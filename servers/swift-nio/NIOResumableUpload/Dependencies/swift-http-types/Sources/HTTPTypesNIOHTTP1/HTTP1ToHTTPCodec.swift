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

import NIOCore
import NIOHTTP1
import HTTPTypesNIO

/// A simple channel handler that translates HTTP/1 messages into shared HTTP types,
/// and vice versa, for use on the client side.
public final class HTTP1ToHTTPClientCodec: ChannelInboundHandler, ChannelOutboundHandler {
    public typealias InboundIn = HTTPClientResponsePart
    public typealias InboundOut = HTTPTypeClientResponsePart

    public typealias OutboundIn = HTTPTypeClientRequestPart
    public typealias OutboundOut = HTTPClientRequestPart

    /// Initializes a `HTTP1ToHTTPClientCodec`.
    public init() {
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            do {
                context.fireChannelRead(wrapInboundOut(.head(try head.newResponse)))
            } catch {
                context.fireErrorCaught(error)
            }
        case .body(let body):
            context.fireChannelRead(wrapInboundOut(.body(body)))
        case .end(let trailers):
            context.fireChannelRead(wrapInboundOut(.end(trailers?.newFields(splitCookie: false))))
        }
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        switch unwrapOutboundIn(data) {
        case .head(let request):
            do {
                context.write(wrapOutboundOut(.head(try HTTPRequestHead(request))), promise: promise)
            } catch {
                context.fireErrorCaught(error)
            }
        case .body(let body):
            context.write(wrapOutboundOut(.body(body)), promise: promise)
        case .end(let trailers):
            context.write(wrapOutboundOut(.end(trailers.map(HTTPHeaders.init))), promise: promise)
        }
    }
}

/// A simple channel handler that translates HTTP/1 messages into shared HTTP types,
/// and vice versa, for use on the server side.
public final class HTTP1ToHTTPServerCodec: ChannelInboundHandler, ChannelOutboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias InboundOut = HTTPTypeServerRequestPart

    public typealias OutboundIn = HTTPTypeServerResponsePart
    public typealias OutboundOut = HTTPServerResponsePart

    private let secure: Bool
    private let splitCookie: Bool

    /// Initializes a `HTTP1ToHTTPServerCodec`.
    /// - Parameters:
    ///   - secure: Whether "https" or "http" is used.
    ///   - splitCookie: Whether the cookies received from the server should be split
    ///                  into multiple header fields. Defaults to false.
    public init(secure: Bool, splitCookie: Bool = false) {
        self.secure = secure
        self.splitCookie = splitCookie
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            do {
                context.fireChannelRead(wrapInboundOut(.head(try head.newRequest(secure: secure, splitCookie: splitCookie))))
            } catch {
                context.fireErrorCaught(error)
            }
        case .body(let body):
            context.fireChannelRead(wrapInboundOut(.body(body)))
        case .end(let trailers):
            context.fireChannelRead(wrapInboundOut(.end(trailers?.newFields(splitCookie: false))))
        }
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        switch unwrapOutboundIn(data) {
        case .head(let response):
            context.write(wrapOutboundOut(.head(HTTPResponseHead(response))), promise: promise)
        case .body(let body):
            context.write(wrapOutboundOut(.body(body)), promise: promise)
        case .end(let trailers):
            context.write(wrapOutboundOut(.end(trailers.map(HTTPHeaders.init))), promise: promise)
        }
    }
}