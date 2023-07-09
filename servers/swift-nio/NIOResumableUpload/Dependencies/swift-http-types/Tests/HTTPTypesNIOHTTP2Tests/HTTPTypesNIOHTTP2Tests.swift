/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dependency of the sample code project.
*/
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
import NIOCore
import NIOEmbedded
import NIOHTTP2
import NIOHPACK
import HTTPTypes
import HTTPTypesNIO
import HTTPTypesNIOHTTP2

/// A handler that keeps track of all reads made on a channel.
private final class InboundRecorder<Frame>: ChannelInboundHandler {
    typealias InboundIn = Frame

    var receivedFrames: [Frame] = []

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        self.receivedFrames.append(self.unwrapInboundIn(data))
    }
}

private extension HTTPField.Name {
    static let xFoo = Self("X-Foo")!
}

private extension HTTP2Frame.FramePayload {
    var headers: HPACKHeaders? {
        if case .headers(let headers) = self {
            return headers.headers
        } else {
            return nil
        }
    }

    init(headers: HPACKHeaders) {
        self = .headers(.init(headers: headers))
    }
}

final class HTTPTypesNIOHTTP2Tests: XCTestCase {
    var channel: EmbeddedChannel!

    override func setUp() {
        super.setUp()
        self.channel = EmbeddedChannel()
    }

    override func tearDown() {
        self.channel = nil
        super.tearDown()
    }

    static let request: HTTPRequest = {
        var request = HTTPRequest(method: .get, scheme: "https", authority: "www.example.com", path: "/", headerFields: [
            .accept: "*/*",
            .acceptEncoding: "gzip",
            .acceptEncoding: "br",
            .trailer: "X-Foo",
            .cookie: "a=b",
            .cookie: "c=d"
        ])
        request.methodField.indexingStrategy = .automatic
        request.schemeField?.indexingStrategy = .automatic
        request.authorityField?.indexingStrategy = .automatic
        return request
    }()

    static let oldRequest: HPACKHeaders = [
        ":method": "GET",
        ":scheme": "https",
        ":authority": "www.example.com",
        ":path": "/",
        "accept": "*/*",
        "accept-encoding": "gzip",
        "accept-encoding": "br",
        "trailer": "X-Foo",
        "cookie": "a=b",
        "cookie": "c=d"
    ]

    static let response = HTTPResponse(status: .ok, headerFields: [
        .server: "HTTPServer/1.0",
        .trailer: "X-Foo"
    ])

    static let oldResponse: HPACKHeaders = [
        ":status": "200",
        "server": "HTTPServer/1.0",
        "trailer": "X-Foo"
    ]

    static let trailers: HTTPFields = [.xFoo: "Bar"]

    static let oldTrailers: HPACKHeaders = ["x-foo": "Bar"]

    func testClientHTTP2ToHTTP() throws {
        let recorder = InboundRecorder<HTTPTypeClientResponsePart>()

        try self.channel.pipeline.addHandlers(HTTP2FramePayloadToHTTPClientCodec(), recorder).wait()

        try self.channel.writeOutbound(HTTPTypeClientRequestPart.head(Self.request))
        try self.channel.writeOutbound(HTTPTypeClientRequestPart.end(Self.trailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTP2Frame.FramePayload.self)?.headers, Self.oldRequest)
        XCTAssertEqual(try self.channel.readOutbound(as: HTTP2Frame.FramePayload.self)?.headers, Self.oldTrailers)

        try self.channel.writeInbound(HTTP2Frame.FramePayload(headers: Self.oldResponse))
        try self.channel.writeInbound(HTTP2Frame.FramePayload(headers: Self.oldTrailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.response))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.trailers))

        XCTAssertTrue(try channel.finish().isClean)
    }

    func testServerHTTP2ToHTTP() throws {
        let recorder = InboundRecorder<HTTPTypeServerRequestPart>()

        try self.channel.pipeline.addHandlers(HTTP2FramePayloadToHTTPServerCodec(), recorder).wait()

        try self.channel.writeInbound(HTTP2Frame.FramePayload(headers: Self.oldRequest))
        try self.channel.writeInbound(HTTP2Frame.FramePayload(headers: Self.oldTrailers))

        XCTAssertEqual(recorder.receivedFrames[0], .head(Self.request))
        XCTAssertEqual(recorder.receivedFrames[1], .end(Self.trailers))

        try self.channel.writeOutbound(HTTPTypeServerResponsePart.head(Self.response))
        try self.channel.writeOutbound(HTTPTypeServerResponsePart.end(Self.trailers))

        XCTAssertEqual(try self.channel.readOutbound(as: HTTP2Frame.FramePayload.self)?.headers, Self.oldResponse)
        XCTAssertEqual(try self.channel.readOutbound(as: HTTP2Frame.FramePayload.self)?.headers, Self.oldTrailers)

        XCTAssertTrue(try channel.finish().isClean)
    }
}
