// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

/**
  @title A generic HTML builder that fetches and assembles given JS requests.
  @author @0xthedude
  @author @xtremetom

  Special thanks to @cxkoda and @frolic
*/

import {DynamicBuffer} from "./utils/DynamicBuffer.sol";
import {AddressChunks} from "./utils/AddressChunks.sol";

import {IScriptyBuilder, InlineScriptRequest, WrappedScriptRequest} from "./IScriptyBuilder.sol";
import {IScriptyStorage} from "./IScriptyStorage.sol";
import {IContractScript} from "./IContractScript.sol";

contract ScriptyBuilder is IScriptyBuilder {
    using DynamicBuffer for bytes;

    // <html>,
    // raw
    // 6 bytes
    bytes public constant HTML_TAG_RAW = "<html>";
    // url encoded
    // 21 bytes
    bytes public constant HTML_TAG_URL_SAFE = "data%3Atext%2Fhtml%2C";

    // <body style='margin:0;'>
    // 24 bytes
    bytes public constant HTML_BODY_OPEN_RAW = "<body style='margin:0;'>";
    // url encoded
    // 56 bytes
    bytes public constant HTML_BODY_OPEN_URL_SAFE =
        "%253Cbody%2520style%253D%2527margin%253A0%253B%2527%253E";

    // </body></html>
    // 14 bytes
    bytes public constant HTML_BODY_CLOSED_RAW = "</body></html>";
    // 19 bytes
    bytes public constant HTML_BODY_CLOSED_URL_SAFE = "%253C%252Fbody%253E";

    // HTML_TAG_RAW + HTML_BODY_OPEN_RAW + HTML_BODY_CLOSED_RAW
    uint256 public constant URLS_RAW_BYTES = 44;

    // HTML_TAG_URL_SAFE + HTML_BODY_OPEN_URL_SAFE + HTML_BODY_CLOSED_URL_SAFE
    uint256 public constant URLS_SAFE_BYTES = 96;

    // <script></script>
    uint256 public constant SCRIPT_INLINE_BYTES = 17;

    // data:text/html;base64,
    uint256 public constant HTML_BASE64_DATA_URI_BYTES = 22;

    // =============================================================
    //                      RAW HTML GETTERS
    // =============================================================

    /**
     * @notice Get requested scripts housed in <body> with custom wrappers
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (bytes memory) {
        uint256 length = requests.length;
        if (length == 0) revert InvalidRequestsLength();

        bytes memory htmlFile = DynamicBuffer.allocate(bufferSize);
        htmlFile.appendSafe(HTML_TAG_RAW);
        htmlFile.appendSafe(HTML_BODY_OPEN_RAW);

        bytes memory wrapPrefix;
        bytes memory wrapSuffix;
        WrappedScriptRequest memory request;
        uint256 i;

        unchecked {
            do {
                request = requests[i];
                (wrapPrefix, wrapSuffix) = wrapPrefixAndSuffixFor(request);
                htmlFile.appendSafe(wrapPrefix);

                htmlFile.appendSafe(
                    fetchScript(
                        request.name,
                        request.contractAddress,
                        request.contractData,
                        request.scriptContent
                    )
                );

                htmlFile.appendSafe(wrapSuffix);
            } while (++i < length);
        }

        htmlFile.appendSafe(HTML_BODY_CLOSED_RAW);
        return htmlFile;
    }

    /**
     * @notice Get requested scripts housed in URL Safe wrappers
     * @dev Any wrapper type 0 scripts are converted to base64 and wrapped
     *      with <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      [WARNING]: Large non-base64 libraries that need base64 encoding
     *      carry a high risk of causing a gas out. Highly advised the use
     *      of base64 encoded scripts where possible
     *
     *      Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full URL Safe wrapped scripts
     */
    function getHTMLWrappedURLSafe(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (bytes memory) {
        uint256 length = requests.length;
        if (length == 0) revert InvalidRequestsLength();

        bytes memory htmlFile = DynamicBuffer.allocate(bufferSize);
        htmlFile.appendSafe(HTML_TAG_URL_SAFE);
        htmlFile.appendSafe(HTML_BODY_OPEN_URL_SAFE);

        bytes memory wrapPrefix;
        bytes memory wrapSuffix;
        WrappedScriptRequest memory request;
        uint256 i;

        // Iterate through scripts and convert any non base64 into base64
        // Dont touch any existing base64
        // Wrap code in appropriate urlencoded tags
        unchecked {
            do {
                request = requests[i];
                (wrapPrefix, wrapSuffix) = wrapURLSafePrefixAndSuffixFor(
                    request
                );
                htmlFile.appendSafe(wrapPrefix);

                // convert raw code into base64
                if (request.wrapType == 0) {
                    htmlFile.appendSafeBase64(
                        fetchScript(
                            request.name,
                            request.contractAddress,
                            request.contractData,
                            request.scriptContent
                        ),
                        false,
                        false
                    );
                } else {
                    htmlFile.appendSafe(
                        fetchScript(
                            request.name,
                            request.contractAddress,
                            request.contractData,
                            request.scriptContent
                        )
                    );
                }
                htmlFile.appendSafe(wrapSuffix);
            } while (++i < length);
        }

        htmlFile.appendSafe(HTML_BODY_CLOSED_URL_SAFE);
        return htmlFile;
    }

    /**
     * @notice Get requested scripts housed in <body> all wrapped in <script></script>
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              <script>
     *                  {request[0]}
     *                  {request[1]}
     *                  ...
     *                  {request[n]}
     *              </script>
     *          </body>
     *      </html>
     * @param requests - Array of InlineScriptRequest
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (bytes memory) {
        uint256 length = requests.length;
        if (length == 0) revert InvalidRequestsLength();

        bytes memory htmlFile = DynamicBuffer.allocate(bufferSize);
        htmlFile.appendSafe(HTML_TAG_RAW);
        htmlFile.appendSafe(HTML_BODY_OPEN_RAW);
        htmlFile.appendSafe("<script>");

        InlineScriptRequest memory request;
        uint256 i;

        unchecked {
            do {
                request = requests[i];
                htmlFile.appendSafe(
                    fetchScript(
                        request.name,
                        request.contractAddress,
                        request.contractData,
                        request.scriptContent
                    )
                );
            } while (++i < length);
        }

        htmlFile.appendSafe("</script>");
        htmlFile.appendSafe(HTML_BODY_CLOSED_RAW);
        return htmlFile;
    }

    // =============================================================
    //                      ENCODED HTML GETTERS
    // =============================================================

    /**
     * @notice Get {getHTMLWrapped} and base64 encode it
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (bytes memory) {
        unchecked {
            bytes memory rawHTML = getHTMLWrapped(requests, bufferSize);

            uint256 sizeForEncoding = HTML_BASE64_DATA_URI_BYTES +
                sizeForBase64Encoding(rawHTML.length);

            bytes memory htmlFile = DynamicBuffer.allocate(sizeForEncoding);
            htmlFile.appendSafe("data:text/html;base64,");
            htmlFile.appendSafeBase64(rawHTML, false, false);
            return htmlFile;
        }
    }

    /**
     * @notice Get {getHTMLInline} and base64 encode it
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (bytes memory) {
        unchecked {
            bytes memory rawHTML = getHTMLInline(requests, bufferSize);

            uint256 sizeForEncoding = HTML_BASE64_DATA_URI_BYTES +
                sizeForBase64Encoding(rawHTML.length);

            bytes memory htmlFile = DynamicBuffer.allocate(sizeForEncoding);
            htmlFile.appendSafe("data:text/html;base64,");
            htmlFile.appendSafeBase64(rawHTML, false, false);

            return htmlFile;
        }
    }

    // =============================================================
    //                      STRING UTILITIES
    // =============================================================

    /**
     * @notice Convert {getHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLWrapped} as a string
     */
    function getHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (string memory) {
        return string(getHTMLWrapped(requests, bufferSize));
    }

    /**
     * @notice Convert {getHTMLWrappedURLSafe} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLWrappedURLSafe} as a string
     */
    function getURLSafeHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (string memory) {
        return string(getHTMLWrappedURLSafe(requests, bufferSize));
    }

    /**
     * @notice Convert {getHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLInline} as a string
     */
    function getHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (string memory) {
        return string(getHTMLInline(requests, bufferSize));
    }

    /**
     * @notice Convert {getEncodedHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getEncodedHTMLWrapped} as a string
     */
    function getEncodedHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (string memory) {
        return string(getEncodedHTMLWrapped(requests, bufferSize));
    }

    /**
     * @notice Convert {getEncodedHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getEncodedHTMLInline} as a string
     */
    function getEncodedHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) public view returns (string memory) {
        return string(getEncodedHTMLInline(requests, bufferSize));
    }

    // =============================================================
    //                      OFF-CHAIN UTILITIES
    // =============================================================

    /**
     * @notice Get the buffer size of a single inline requested code
     * @param request - InlineScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getInlineScriptSize(InlineScriptRequest memory request)
        public
        view
        returns (uint256)
    {
        return
            fetchScript(
                request.name,
                request.contractAddress,
                request.contractData,
                request.scriptContent
            ).length;
    }

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getWrappedScriptSize(WrappedScriptRequest memory request)
        public
        view
        returns (uint256)
    {
        unchecked {
            (
                bytes memory wrapPrefix,
                bytes memory wrapSuffix
            ) = wrapPrefixAndSuffixFor(request);

            uint256 scriptSize = fetchScript(
                request.name,
                request.contractAddress,
                request.contractData,
                request.scriptContent
            ).length;

            return wrapPrefix.length + wrapSuffix.length + scriptSize;
        }
    }

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @dev If the script is of wrapper type 0, we get buffer size for
     *      base64 encoded version.
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getURLSafeWrappedScriptSize(WrappedScriptRequest memory request)
        public
        view
        returns (uint256)
    {
        unchecked {
            (
                bytes memory wrapPrefix,
                bytes memory wrapSuffix
            ) = wrapURLSafePrefixAndSuffixFor(request);

            uint256 scriptSize = fetchScript(
                request.name,
                request.contractAddress,
                request.contractData,
                request.scriptContent
            ).length;

            if (request.wrapType == 0) {
                scriptSize = sizeForBase64Encoding(scriptSize);
            }

            return wrapPrefix.length + wrapSuffix.length + scriptSize;
        }
    }

    /**
     * @notice Get the buffer size of an array of html wrapped inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLInline(InlineScriptRequest[] calldata requests)
        public
        view
        returns (uint256)
    {
        uint256 size;
        uint256 i;
        uint256 length = requests.length;
        InlineScriptRequest memory request;

        unchecked {
            if (length > 0) {
                do {
                    request = requests[i];
                    size += getInlineScriptSize(request);
                } while (++i < length);
            }
            return size + URLS_RAW_BYTES + SCRIPT_INLINE_BYTES;
        }
    }

    /**
     * @notice Get the buffer size of an array of html wrapped, wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) public view returns (uint256) {
        uint256 size;
        uint256 i;
        uint256 length = requests.length;
        WrappedScriptRequest memory request;

        unchecked {
            if (length > 0) {
                do {
                    request = requests[i];
                    size += getWrappedScriptSize(request);
                } while (++i < length);
            }
            return size + URLS_RAW_BYTES;
        }
    }

    /**
     * @notice Get the buffer size of an array of URL safe html wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForURLSafeHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) public view returns (uint256) {
        uint256 size;
        uint256 i;
        uint256 length = requests.length;
        WrappedScriptRequest memory request;

        unchecked {
            if (length > 0) {
                do {
                    request = requests[i];
                    size += getURLSafeWrappedScriptSize(request);
                } while (++i < length);
            }
            return size + URLS_SAFE_BYTES;
        }
    }

    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLInline(
        InlineScriptRequest[] calldata requests
    ) public view returns (uint256) {
        unchecked {
            uint256 size = getBufferSizeForHTMLInline(requests);
            return HTML_BASE64_DATA_URI_BYTES + sizeForBase64Encoding(size);
        }
    }

    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) public view returns (uint256) {
        unchecked {
            uint256 size = getBufferSizeForHTMLWrapped(requests);
            return HTML_BASE64_DATA_URI_BYTES + sizeForBase64Encoding(size);
        }
    }

    // =============================================================
    //                           INTERNAL
    // =============================================================

    /**
     * @notice Grabs requested script from storage
     * @param scriptName - Name given to the script. Eg: threejs.min.js_r148
     * @param storageAddress - Address of scripty storage contract
     * @param contractData - Arbitrary data to be passed to storage
     * @param scriptContent - Small custom script to inject
     * @return Requested script as bytes
     */
    function fetchScript(
        string memory scriptName,
        address storageAddress,
        bytes memory contractData,
        bytes memory scriptContent
    ) internal view returns (bytes memory) {
        if (scriptContent.length > 0) {
            return scriptContent;
        }

        return
            IContractScript(storageAddress).getScript(scriptName, contractData);
    }

    /**
     * @notice Grab script wrapping based on script type
     * @dev
     *      wrapType: 0:
     *          <script>[SCRIPT]</script>
     *
     *      wrapType: 1:
     *          <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 2:
     *          <script type="text/javascript+gzip" src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 3
     *          <script type="text/javascript+png" name="[NAME]" src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 4 or any other:
     *          [wrapPrefix][scriptContent or scriptFromContract][wrapSuffix]
     *
     *
     *      [IMPORTANT NOTE]: The tags `text/javascript+gzip` and `text/javascript+png` are used to identify scripts
     *      during decompression
     *
     * @param request - WrappedScriptRequest data for code
     * @return (prefix, suffix) - Type specific prefix and suffix as a tuple
     */
    function wrapPrefixAndSuffixFor(WrappedScriptRequest memory request)
    internal
    pure
    returns (bytes memory, bytes memory)
    {
        if (request.wrapType == 0) {
            return ("<script>", "</script>");
        } else if (request.wrapType == 1) {
            return ('<script src="data:text/javascript;base64,', '"></script>');
        } else if (request.wrapType == 2) {
            return (
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            '"></script>'
            );
        } else if (request.wrapType == 3) {
            return (
            '<script type="text/javascript+png" src="data:text/javascript;base64,',
            '"></script>'
            );
        }
        return (request.wrapPrefix, request.wrapSuffix);
    }

    /**
     * @notice Grab URL safe script wrapping based on script type
     * @dev
     *      wrapType: 0:
     *      wrapType: 1:
     *          <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 2:
     *          <script type="text/javascript+gzip" src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 3
     *          <script type="text/javascript+png" name="[NAME]" src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      wrapType: 4 or any other:
     *          [wrapPrefix][scriptContent or scriptFromContract][wrapSuffix]
     *
     *
     *      [IMPORTANT NOTE]: The tags `text/javascript+gzip` and `text/javascript+png` are used to identify scripts
     *      during decompression
     *
     * @param request - WrappedScriptRequest data for code
     * @return (prefix, suffix) - Type specific prefix and suffix as a tuple
     */
    function wrapURLSafePrefixAndSuffixFor(WrappedScriptRequest memory request)
    internal
    pure
    returns (bytes memory, bytes memory)
    {
        if (request.wrapType <= 1) {
            // <script src="data:text/javascript;base64,
            // "></script>
            return (
            "%253Cscript%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            "%2522%253E%253C%252Fscript%253E"
            );
        } else if (request.wrapType == 2) {
            // <script type="text/javascript+gzip" src="data:text/javascript;base64,
            // "></script>
            return (
            "%253Cscript%2520type%253D%2522text%252Fjavascript%252Bgzip%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            "%2522%253E%253C%252Fscript%253E"
            );
        } else if (request.wrapType == 3) {
            // <script type="text/javascript+png" src="data:text/javascript;base64,
            // "></script>
            return (
            "%253Cscript%2520type%253D%2522text%252Fjavascript%252Bpng%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            "%2522%253E%253C%252Fscript%253E"
            );
        }
        return (request.wrapPrefix, request.wrapSuffix);
    }

    /**
     * @notice Calculate the buffer size post base64 encoding
     * @param value - Starting buffer size
     * @return Final buffer size as uint256
     */
    function sizeForBase64Encoding(uint256 value)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

// =============================================================
//                            STRUCTS
// =============================================================

struct WrappedScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    uint8 wrapType;
    bytes wrapPrefix;
    bytes wrapSuffix;
    bytes scriptContent;
}

struct InlineScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    bytes scriptContent;
}

interface IScriptyBuilder {

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @notice Error for, Invalid length of requests
     */
    error InvalidRequestsLength();

    // =============================================================
    //                      RAW HTML GETTERS
    // =============================================================

    /**
     * @notice Get requested scripts housed in <body> with custom wrappers
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in URL Safe wrappers
     * @dev Any wrapper type 0 scripts are converted to base64 and wrapped
     *      with <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      [WARNING]: Large non-base64 libraries that need base64 encoding
     *      carry a high risk of causing a gas out. Highly advised to use
     *      base64 encoded scripts where possible
     *
     *      Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full URL Safe wrapped scripts
     */
    function getHTMLWrappedURLSafe(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in <body> all wrapped in <script></script>
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              <script>
     *                  {request[0]}
     *                  {request[1]}
     *                  ...
     *                  {request[n]}
     *              </script>
     *          </body>
     *      </html>
     * @param requests - Array of InlineScriptRequest
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      ENCODED HTML GETTERS
    // =============================================================

    /**
     * @notice Get {getHTMLWrapped} and base64 encode it
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get {getHTMLInline} and base64 encode it
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      STRING UTILITIES
    // =============================================================

    /**
     * @notice Convert {getHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLWrapped} as a string
     */
    function getHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLInline} as a string
     */
    function getHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLWrapped} as a string
     */
    function getEncodedHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLInline} as a string
     */
    function getEncodedHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    // =============================================================
    //                      OFF-CHAIN UTILITIES
    // =============================================================

    /**
     * @notice Get the buffer size of a single inline requested code
     * @param request - InlineScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getInlineScriptSize(InlineScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getWrappedScriptSize(WrappedScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @dev If the script is of wrapper type 0, we get buffer size for
     *      base64 encoded version.
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getURLSafeWrappedScriptSize(WrappedScriptRequest memory request)
    external
    view
    returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLInline(InlineScriptRequest[] calldata requests)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped, wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size of an array of URL safe html wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForURLSafeHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
    
    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLInline(
        InlineScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

interface IContractScript {
    // =============================================================
    //                            GETTERS
    // =============================================================

    /**
     * @notice Get the full script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param data - Arbitrary data to be passed to storage
     * @return script - Full script from merged chunks
     */
    function getScript(string calldata name, bytes memory data)
        external
        view
        returns (bytes memory script);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity_ The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity_ + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity_)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity_, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        checkOverflow(buffer, encodedLength);

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendUncheckedBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Returns the capacity of a given buffer.
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }

    /// @notice Reverts if the buffer will overflow after appending a given
    /// number of bytes.
    function checkOverflow(bytes memory buffer, uint256 addedLength)
        internal
        pure
    {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

interface IScriptyStorage {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct Script {
        bool isVerified;
        address owner;
        uint256 size;
        bytes details;
        address[] chunks;
    }

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @notice Error for, The Script you are trying to create already exists
     */
    error ScriptExists();

    /**
     * @notice Error for, You dont have permissions to perform this action
     */
    error NotScriptOwner();

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @notice Event for, Successful update of script verification status
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param isVerified - Verification status of the script
     */
    event ScriptVerificationUpdated(string indexed name, bool isVerified);

    /**
     * @notice Event for, Successful creation of a script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param owner - Address of the script owner
     * @param details - Custom details of the script
     */
    event ScriptCreated(string indexed name, address owner, bytes details);

    /**
     * @notice Event for, Successful addition of script chunk
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param size - Bytes size of the chunk
     */
    event ChunkStored(string indexed name, uint256 size);

    /**
     * @notice Event for, Successful update of custom details
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param owner - Address of the script owner
     * @param details - Custom details of the script
     */
    event ScriptDetailsUpdated(
        string indexed name,
        address owner,
        bytes details
    );

    // =============================================================
    //                      MANAGEMENT OPERATIONS
    // =============================================================

    /**
     * @notice Create a new script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptCreated} event.
     */
    function createScript(string calldata name, bytes calldata details)
        external;

    /**
     * @notice Add a code chunk to the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param chunk - Next sequential code chunk
     *
     * Emits an {ChunkStored} event.
     */
    function addChunkToScript(string calldata name, bytes calldata chunk)
        external;

    /**
     * @notice Edit the script details
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptDetailsUpdated} event.
     */
    function updateDetails(string calldata name, bytes calldata details)
        external;

    /**
     * @notice Update the verification status of the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param isVerified - The verification status
     *
     * Emits an {ScriptVerificationUpdated} event.
     */
    function updateScriptVerification(string calldata name, bool isVerified)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title AddressChunks
 * @author @xtremetom
 * @notice Reads chunk pointers and merges their values
 */
library AddressChunks {
    function mergeChunks(address[] memory chunks)
        internal
        view
        returns (bytes memory o_code)
    {
        unchecked {
            assembly {
                let len := mload(chunks)
                let totalSize := 0x20
                let size := 0
                o_code := mload(0x40)

                // loop through all chunk addresses
                // - get address
                // - get data size
                // - get code and add to o_code
                // - update total size
                let targetChunk := 0
                for {
                    let i := 0
                } lt(i, len) {
                    i := add(i, 1)
                } {
                    targetChunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
                    size := sub(extcodesize(targetChunk), 1)
                    extcodecopy(targetChunk, add(o_code, totalSize), 1, size)
                    totalSize := add(totalSize, size)
                }

                // update o_code size
                mstore(o_code, sub(totalSize, 0x20))
                // store o_code
                mstore(0x40, add(o_code, and(add(totalSize, 0x1f), not(0x1f))))
            }
        }
    }
}