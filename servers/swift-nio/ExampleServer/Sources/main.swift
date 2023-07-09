import Foundation
import NIOHTTP1
import NIO
import NIOTransportServices
import NIOResumableUpload
import HTTPTypesNIOHTTP1
import HTTPTypesNIO
import HTTPTypes

let HOST = "127.0.0.1"
let PORT = 8080

let uploadContext = HTTPResumableUploadContext(origin: "http://\(HOST):\(PORT)")

final class UploadHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPTypeServerRequestPart
    typealias OutboundOut = HTTPTypeServerResponsePart
    
    private var bodyLength: Int = 0

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)

        switch part {
        case .head(let request):
            print("[\(request.method)] \(request.path ?? "n/a")")

            // Continue reading the request body
            context.read()
        case .body(let body):
            // Accumulate the request body
            bodyLength += body.readableBytes
        case .end:
            // Prepare the response body
            let responseBody = "Receive a request with body length: \(bodyLength)"
            print(responseBody)

            var responseHead = HTTPResponse(status: .init(code: 200))
            responseHead.headerFields[.contentType] = "text/plain"
            responseHead.headerFields[.contentLength] = "\(responseBody.count)"
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)

            // Set the data
            let buffer = context.channel.allocator.buffer(string: responseBody)
            context.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
    }
}

func start() {
    do {
        let group = NIOTSEventLoopGroup()

        let bootstrap = NIOTSListenerBootstrap(group: group)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap {
                        channel.pipeline.addHandlers([
                            HTTP1ToHTTPServerCodec(secure: false), // No HTTPS for now
                            HTTPResumableUploadHandler(context: uploadContext, handlers: [
                                UploadHandler()
                            ])
                    ])
                }
        }
        
        print("Server listening on \(HOST):\(PORT)")
        
        let channel = try bootstrap
            .bind(host: HOST, port: PORT)
            .wait()
        
        try channel.closeFuture.wait()
    } catch {
        print("An error happed \(error.localizedDescription)")
        exit(1)
    }
}

start()
