# tus-js-client Resumable Upload Client

[tus-js-client](https://github.com/tus/tus-js-client) is a client implementing the [tus resumable upload protocol](https://tus.io). In an [unreleased branch](https://github.com/tus/tus-js-client/pull/609), it also provides experimental support for the resumable upload draft from the HTTP working group. It is a feature-rich upload client for various JavaScript environments, such as browsers, Node.js and React Native.

## Running

To run this example, you need to have Node.js and Yarn installed.

```sh
# Clone repository from development branch
git clone -b ietf-draft https://github.com/tus/tus-js-client.git
cd tus-js-client

# Install dependencies
yarn install

# Build library
yarn run build

# Open example in browser
open demos/browser/index.html
```

Finally, open `tus-js-client/demos/browser/index.html` and use the UI to specify the URL of the resumable upload server, select a file for upload and pause/resume the upload. You can also use your browser's developer tools to throttle network speed and inspect requests directly.
