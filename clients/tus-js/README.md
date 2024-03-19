# tus-js-client Resumable Upload Client

[tus-js-client](https://github.com/tus/tus-js-client) is a client implementing the [tus resumable upload protocol](https://tus.io). Since the [v4.1.0 release](https://github.com/tus/tus-js-client/releases/tag/v4.1.0), it also provides experimental support for the resumable upload draft from the HTTP working group behind a [feature flag](https://github.com/tus/tus-js-client/blob/main/docs/api.md#protocol). It is a feature-rich upload client for various JavaScript environments, such as browsers, Node.js and React Native.

## Running

To run this example, you don't need to install any dependencies but just clone the repository:

```sh
git clone https://github.com/tus/rufh-implementations.git
```

Finally, open `rufh-implementations/client/tus-js/demo.html` in your browser and use the UI to specify the URL of the resumable upload server, select a file for upload and pause/resume the upload. You can also use your browser's developer tools to throttle network speed and inspect requests directly.
