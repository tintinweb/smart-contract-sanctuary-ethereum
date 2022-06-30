/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT

/*
Contract that's primarily responsible for generating the metadata, including the image itself in SVG.
Parts of the SVG is encapsulated into custom re-usable components specific to this collection.
*/

pragma solidity ^0.8.9;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract CollectionDescriptor {

    function generateName(uint nr, bool redeemed) public pure returns (string memory) {
        if (redeemed) {
            return string(abi.encodePacked('Redeemed PM #', toString(nr)));
        }
        return string(abi.encodePacked('PM #', toString(nr)));
    }

    function generateTraits(uint256 tokenId) public pure returns (string memory) {
        if (tokenId > 1000) {
            return "invalid tokenid";
        }
        return string(abi.encodePacked(
            '"attributes": [',
            '{"trait_type": "Fineness", "value": "999"},',
            '{"trait_type": "Troy Ounce Weight", "value": "1"},',
            '{"trait_type": "Size", "value": "40x80x18"}',
            ']'
        ));
    }
    function generateRGB(uint256 tokenId, uint256 hashIndex) public pure returns (uint256) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillr = uint256(toUint8(hash,hashIndex))*250/256;
        return fillr;
     }

    function generateImage(uint256 tokenId,bool redeemed) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillI = uint256(toUint8(hash,1));
        string memory fill = 'none';
        if(fillI < 128) { fill = 'white'; }

        if (redeemed) {
            return string(
                abi.encodePacked(
'<?xml version="1.0" encoding="UTF-8"?> <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 800 800" width="800" height="800" x="0px" y="0px"><g><defs><clipPath id="clip-path-id-viewbox-item-0"><rect x="0.0" y="0.0" width="111.06" height="111.061"/></clipPath></defs><g transform="translate(700.0 233.0) rotate(0.0 27.0 27.0) scale(0.4862236628849271 0.4862192848974887)"><g clip-path="url(#clip-path-id-viewbox-item-0)" transform="translate(-0.0 -0.0)"><defs><radialGradient id="coolcat_14-i0" data-name="coolcat 14" cx="55.53" cy="55.53" r="51.237" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff4c2"/><stop offset="0.772" stop-color="#faba10"/></radialGradient></defs></g></g><g><defs><clipPath id="clip-path-id-viewbox-item-1"><rect x="0.0" y="0.0" width="782.44" height="108.77"/></clipPath></defs>',
'<g transform="translate(9.0 651.0) rotate(0.0 389.0 53.5) scale(0.9943254434844844 0.9837271306426405)"><g clip-path="url(#clip-path-id-viewbox-item-1)" transform="translate(-0.0 -0.0)"><defs><linearGradient id="coolcat_20-i1" data-name="coolcat 20" x1="391.66" y1="112.234" x2="391.66" y2="17.084" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#8d827b"/><stop offset="1" stop-color="#685e57"/></linearGradient></defs><g><path d="M782.44,2.84a2.879,2.879,0,0,1-2.84,2.89S7.47,8.12,4,8.14H3.99a6.619,6.619,0,0,1-1.57-.17A2.779,2.779,0,0,1,0,5.14,2.552,2.552,0,0,1,2.42,2.27,8.125,8.125,0,0,1,4,2.14l82.5-.23L779.56,0A2.9,2.9,0,0,1,782.44,2.84Z" style="fill:#623310"/></g></g></g></g><g><defs><clipPath id="clip-path-id-viewbox-item-2"><rect x="0.0" y="0.0" width="707.306" height="691.154"/></clipPath></defs><g transform="translate(40.0 36.0) rotate(0.0 353.5 345.5) scale(0.9995673725374873 0.9997771842454793)">',
'<g clip-path="url(#clip-path-id-viewbox-item-2)" transform="translate(-0.0 -0.0)"><g><path d="M704.366,601.324a72.031,72.031,0,0,1-2.123,14.237q-13.608.186-27.377.407c-22.744.336-45.789.672-68.887,1.008a2.844,2.844,0,0,0-.389.017,1.04,1.04,0,0,0-.23,0c-34.488.5-69.117,1.009-103.127,1.5-.442,0-.884.018-1.326.018h-.283c-30.721.459-60.911.9-90.022,1.344-118.549,62.626-232.34,81.461-309.981,59.8-30.155-8.4-54.862-22.921-72.282-43.366-.513-.619-1.026-1.238-1.557-1.875A107.761,107.761,0,0,1,3.224,556.808a111.894,111.894,0,0,1,6.014-27.66,430.782,430.782,0,0,0,19.6-76.545q.875-5.412,1.627-11.019a337.265,337.265,0,0,0,2.9-61.14l-.017-.265c-.354-7.517-.955-14.591-1.7-21.418-3.184-29.235-9-53.765-9.25-85.847-.053-7.322.177-14.627.69-21.86,5.5-79.357,43.065-152.347,78.136-198.33C127.061,18.82,151.539-.4,160.789,3.309c6.579,2.653,10.363,18.924-.6,76.563,22.886-3.131,50.158-4.74,79.109-4.546,48.035.3,100.739,5.518,145.892,',
'16.908.159-.265.336-.513.5-.778,37.706-58.346,76.615-107.283,66-14.361-2.635,124.527,59.8,163.666,32.117,231.031-5.836,14.22-17.066,33.038-14.926,60.38,1.468,18.57,8.418,32.454,14.926,44.3,9.887,17.4,18.818,31.552,26.989,43.508-.442-2.971-.831-5.907-1.167-8.825q-.769-6.447-1.273-12.681a282.9,282.9,0,0,1,4.156-77.588,218.267,218.267,0,0,1,12.079-40.8A116,116,0,0,1,535.8,294.95c.884-1.255,1.8-2.529,2.759-3.8a4.015,4.015,0,0,0,.248-.336c8.365-11.142,19.366-22.9,29.111-30.756,8.684-7,16.377-10.895,20.339-8.471,8.577,5.252-2.565,38.678-9.8,58.062,14.467-7.728,39.262-18.092,69.947-16.094,3.237.212,34.488,2.423,35.673,11.195.707,5.147-8.861,13.566-52.457,27.979,9.3,4.316,14.485,19.19,10.488,30.774-5.252,15.263-24.672,19.6-37.759,16.784a183.847,183.847,0,0,0,4.881,36.38c5.836,24.46,15.564,42.676,31.87,68.515C683.9,553.077,705.9,568.782,704.366,601.324Z" style="fill:#f9c898"/><path d="M704.366,601.324a72.031,72.031,0,0,',
'1-2.123,14.237q-13.61.186-27.377.406c-22.745.337-45.789.673-68.887,1.009a2.852,2.852,0,0,0-.389.017,390.094,390.094,0,0,0-17.58-46.054,401.412,401.412,0,0,0-72.689-107.76,210.633,210.633,0,0,1-6.968-28.368c-5.96-33.78-8.278-90.552,27.448-139.861.9-1.255,1.822-2.511,2.759-3.8.088-.106.177-.23.248-.336,8.047-10.983,17.3-22.833,29.111-30.756a53.173,53.173,0,0,1,20.338-8.472,12.748,12.748,0,0,1,7.278,3.845c7.635,8.62.661,30.319-17.076,54.218,15-6.007,88.064-34.54,102.8-14.429a14.6,14.6,0,0,1,2.818,9.53c-1.756,19.407-49.756,27.543-52.456,27.979,9.3,4.316,14.484,19.19,10.488,30.774-5.254,15.263-24.673,19.6-37.76,16.784a183.847,183.847,0,0,0,4.881,36.38c5.836,24.46,15.564,42.676,31.87,68.516C683.9,553.077,705.9,568.782,704.366,601.324Z" style="fill:#b14317"/><path d="M316.872,340.1q-1,0-2.008-.051c-9.669-.481-17.818-4.474-22.358-10.954-8.917-12.731-1.162-30.273-.249-32.231a2.861,2.861,0,0,1,4.033-1.263c20.548,11.953,41.629,7.979,50.156-2.776l.037-.048c5.838-7.427,5.8-27.1,5.267-31.73a2.862,2.862,0,1,1,5.687-.657c.442,3.831,1.127,24.568-5.629,34.78,1.242,5.388,3.626,20.946-6.525,32.749C338.736,335.536,327.993,340.1,316.872,340.1ZM296.309,302.14c-1.8,5.094-4.555,15.906.886,23.674,3.518,5.023,10.062,8.129,17.954,8.522,10.093.514,19.981-3.386,25.794-10.144,6.576-7.647,6.695-17.626,5.975-23.665C334.859,310.748,314.568,311.533,296.309,302.14Z" style="fill:#623310"/><path d="M223.62,159.611c2.561,5.7,22.1,3.278,36.372-2.1,8.543-3.217,33.944-12.782,34.273-30.776.225-12.284-11.288-25.668-20.984-25.18-7.641.385-9.138,9.134-24.48,27.978C232.368,149.717,221.571,155.052,223.62,159.611Z" style="fill:#b14317"/><path d="M341.105,276.672q-2.871-22.61-5.743-45.219a16.072,16.072,0,0,1-6.251-4.672c-7.031-9.04-.841-25.877,9.726-30.122,1.591-.639,2.412-.644,16.88,0,16.839.749,18.092.861,19.292,2.165,3.8,4.123-2.023,10.311.024,24.21a45.259,45.259,0,0,0,1.31,6.014q-3.332,23.041-6.664,46.084Z" style="fill:#b14317"/><path d="M375.679,66.545C369.5,68.5,364.653,76,364.63,82.828c-.036,10.767,11.946,13.8,33.244,35.28,12.69,12.8,16.835,20.2,20.257,18.8,4.446-1.811,3.349-16.7,0-27.914C411.163,85.676,389.619,62.133,375.679,66.545Z" style="fill:#b14317"/><path d="M324.459,545.808c.9,5.768-111.44,53.954-162.56,9.934-31.738-27.329-30.6-82.209-22.578-85.344,8.134-3.179,20.038,48.148,65.927,65.927,13.184,5.109,30.314,6.115,64.572,8.128C310.856,546.865,324.152,543.854,324.459,545.808Z" style="fill:#fff;opacity:.44"/></g></g></g></g><g><defs><clipPath id="clip-path-id-viewbox-item-3"><rect x="0.0" y="0.0" width="365.645" height="99.648"/></clipPath></defs><g transform="translate(207.0 226.0) rotate(0.0 182.5 49.5) scale(0.9982359939285373 0.9934971098265897)"><g clip-path="url(#clip-path-id-viewbox-item-3)" transform="translate(-0.0 -0.0)"><g><path d="M359.921,16.8H346.833c3.767,90.358-123.412,95.434-134.165,15.033A17.412,17.412,0,0,0,195.389,16.8h-9a17.53,17.53,0,0,0-17.243,14.892C165.782,52.5,155.454,68.1,141.623,78.466a76.608,76.608,0,0,1-25.609,12.451,84.919,84.919,0,0,1-15.475,2.724c-2.317.194-4.651.283-6.986.283a80.573,80.573,0,0,1-8.772-.46C49.55,89.838,16.867,64.3,16.831,16.8H5.725V5.725h354.2Z" style="fill:rgb(',
 toString(generateRGB(tokenId,0)) , ',' , toString(generateRGB(tokenId,1)) , ',' , toString(generateRGB(tokenId,2)), 
 ')"/><path d="M359.921,5.725V16.8H346.833c1.995,47.837-32.717,71.773-67.42,71.773-30.847,0-61.685-18.9-66.745-56.74A17.411,17.411,0,0,0,195.389,16.8h-9a17.53,17.53,0,0,0-17.243,14.892c-3.36,20.816-13.689,36.415-27.52,46.779a76.608,76.608,0,0,1-25.609,12.451,84.919,84.919,0,0,1-15.475,2.724c-2.317.195-4.651.283-6.986.283a80.573,80.573,0,0,1-8.772-.46C49.55,89.838,16.867,64.3,16.831,16.8H5.725V5.725h354.2m0-5.725H5.725A5.725,5.725,0,0,0,0,5.725V16.8A5.725,5.725,0,0,0,5.725,22.52h5.541c1.173,21.156,8.81,39.418,22.263,53.081C46.489,88.764,64.483,97.13,84.2,99.159a86.508,86.508,0,0,0,9.358.489c2.561,0,5.073-.1,7.465-.3a90.791,90.791,0,0,0,16.5-2.905,82,82,0,0,0,27.54-13.395C161.128,71,171.411,53.559,174.794,32.6A11.8,11.8,0,0,1,186.386,22.52h9A11.72,11.72,0,0,1,207,32.6c2.563,19.165,11.508,35.184,25.868,46.315,12.8,9.919,29.328,15.382,46.55,15.382,20.856,0,40.507-8.016,53.913-21.993,12.3-12.819,18.908-29.936,19.295-49.78h7.3a5.724,5.724,0,0,0,5.724-5.725V5.725A5.724,5.724,0,0,0,359.921,0Z"/><path d="M290.928,87.681,241.62,5.724H225.932l49.822,82.753a62.9,62.9,0,0,0,15.174-.8Z" style="fill:#fff;opacity:.23"/><path d="M329.271,68.261,290.539,5.724H258.227L305.66,83.772a64.153,64.153,0,0,0,23.611-15.511Z" style="fill:#fff;opacity:.23"/><path d="M100.539,93.641l-6.986.283a80.573,80.573,0,0,1-8.772-.46L31.953,5.725H47.64Z" style="fill:#fff;opacity:.23"/><path d="M141.623,78.466a76.608,76.608,0,0,1-25.609,12.451L64.247,5.725H96.56Z" style="fill:#fff;opacity:.23"/></g></g></g></g><g><defs><clipPath id="clip-path-id-viewbox-item-4"><rect x="0.0" y="0.0" width="111.06" height="111.061"/></clipPath></defs><g transform="translate(581.0 109.0) rotate(0.0 55.5 55.5) scale(0.9994597514856834 0.9994507522892824)"><g clip-path="url(#clip-path-id-viewbox-item-4)" transform="translate(-0.0 -0.0)"><defs><radialGradient id="coolcat_14-i5" data-name="coolcat 14" cx="55.53" cy="55.53" r="51.237" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff4c2"/><stop offset="0.772" stop-color="#faba10"/></radialGradient></defs></g></g></g><g><g><path d="M243.79,529.65h9.5c6.96,0,11.67,2.35,11.67,9.26c0,6.67-4.75,9.74-11.67,9.74h-5.47v12.48h-4.03V529.65z M252.81,545.39     c5.47,0,8.11-2.02,8.11-6.48c0-4.51-2.69-6-8.11-6h-4.99v12.48H252.81z"/><path d="M286.85,549.23v-19.58h4.08v19.68c0,6.48,2.83,8.83,6.58,8.83c3.79,0,6.67-2.35,6.67-8.83v-19.68h3.89v19.58     c0,9.03-4.42,12.48-10.56,12.48C291.31,561.71,286.85,558.26,286.85,549.23z"/><path d="M331.96,529.65h9.84c6.38,0,11.04,2.3,11.04,8.88c0,6.29-4.66,9.31-11.04,9.31h-5.76v13.3h-4.08V529.65z M341.23,544.58      c4.9,0,7.58-2.02,7.58-6.05c0-4.13-2.69-5.62-7.58-5.62h-5.18v11.67H341.23z M344.16,544.62l9.6,16.51h-4.56l-8.21-14.4     L344.16,544.62z"/><path d="M374.73,557.73h22.08v3.41h-22.08V557.73z M375.21,529.65h21.12v3.41h-21.12V529.65z M378.33,542.9h14.88v3.41h-14.88 V542.9z"/></g></g></g></svg>')
                );
        }
        
        return string(
            abi.encodePacked('<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"  viewBox="0 0 612 792" style="enable-background:new 0 0 612 792;" xml:space="preserve"><style type="text/css">  .st0{clip-path:url(#SVGID_00000058574021165109556420000003985137933947389575_);}  .st1{fill:#FFFFFF;} .st2{fill:rgb(' ,
            toString(generateRGB(tokenId,0)) , ',' , toString(generateRGB(tokenId,1)) , ',' , toString(generateRGB(tokenId,2)) , 
            ');}</style><g>  <g>   <defs>      <path id="SVGID_1_" d="M182.82,122.68c0,3.24,0,6.48,0,9.71c0,154.28,0,308.56,0,462.84c0,4.32,0,8.65,0,12.97       c20.65,3.12,42.34,5.66,64.99,7.42c76.86,5.96,146.12,1.4,205.17-7.42c1.7-161.84,3.4-323.68,5.1-485.52        c-77.69-9.16-161.36-11.4-249.77-2.77C199.74,120.74,191.24,121.67,182.82,122.68z"/>    </defs>   <clipPath id="SVGID_00000091004766685754875480000001483152757838229162_">     <use xlink:href="#SVGID_1_"  style="overflow:visible;"/>    </clipPath>   <g style="clip-path:url(#SVGID_00000091004766685754875480000001483152757838229162_);">    </g>  </g></g><rect x="238.89" y="202.73" class="st1" width="163.12" height="281.63"/>',
            '<polygon class="st2" points="320.98,241.07 247.18,347.49 247.18,358.75 320.98,446.03 393.73,358.75 393.73,344.5 "/>',
            '<path class="st1" d="M758.82,469.07"/><g>  <g>   <path d="M243.79,529.65h9.5c6.96,0,11.67,2.35,11.67,9.26c0,6.67-4.75,9.74-11.67,9.74h-5.47v12.48h-4.03V529.65z M252.81,545.39     c5.47,0,8.11-2.02,8.11-6.48c0-4.51-2.69-6-8.11-6h-4.99v12.48H252.81z"/>   <path d="M286.85,549.23v-19.58h4.08v19.68c0,6.48,2.83,8.83,6.58,8.83c3.79,0,6.67-2.35,6.67-8.83v-19.68h3.89v19.58     c0,9.03-4.42,12.48-10.56,12.48C291.31,561.71,286.85,558.26,286.85,549.23z"/>    <path d="M331.96,529.65h9.84c6.38,0,11.04,2.3,11.04,8.88c0,6.29-4.66,9.31-11.04,9.31h-5.76v13.3h-4.08V529.65z M341.23,544.58      c4.9,0,7.58-2.02,7.58-6.05c0-4.13-2.69-5.62-7.58-5.62h-5.18v11.67H341.23z M344.16,544.62l9.6,16.51h-4.56l-8.21-14.4     L344.16,544.62z"/>    <path d="M374.73,557.73h22.08v3.41h-22.08V557.73z M375.21,529.65h21.12v3.41h-21.12V529.65z M378.33,542.9h14.88v3.41h-14.88      V542.9z"/>  </g></g></svg>')

        );
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

        // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function generateDecimalString(uint nr, uint decimals) public pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.',toString(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0',toString(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00',toString(nr))); }
        if(decimals == 4) { return string(abi.encodePacked('0.000',toString(nr))); }
        return '0.';
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            // console.logBytes32(computedHash);
            // console.logBytes32(proofElement);
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                //computedHash = _efficientHash(computedHash, proofElement);
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                // computedHash = _efficientHash(proofElement, computedHash);
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.9;



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}




/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}




/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}




pragma solidity ^0.8.9;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // modified from ERC721 template:
    // removed BeforeTokenTransfer
}


pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {
    using Strings for uint256;

    address public owner = 0x1cfA4A195c0933b5b77560CA04965e213e55EABa; // for opensea integration. doesn't do anything else.

    address public collector; // address authorised to withdraw funds recipient
    address payable public recipient; // in this instance, it will be a mirror split on mainnet (to be deployed)

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    CollectionDescriptor public descriptor;

    mapping (address => bool) public claimed;
    mapping (uint => uint) public tokenIdHash;
    bytes32 private loyaltyRoot;

    struct TokenMetaData {
        uint hash;
        bool redeemed;
    }

    mapping (uint => TokenMetaData) public tokenmetadata;

    uint public currentIndex = 1;

    // todo: for testing
    // uint256 public newlyMinted;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        collector = address(msg.sender); 
        recipient = payable(msg.sender);
        startDate = 961871769;
        endDate = 1908556569;
        descriptor = new CollectionDescriptor();
        loyaltyRoot = 0x6ca87a8e2d9d563697d8c9790b077ea5416d1f917a3e4c7bbc31cb9489c40d1d;

        // mint first claim UF. It's a known address in the merkle tree to populate NFT marketplaces before launch
        _createNFT(owner);
        claimed[owner] =  true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId,tokenmetadata[tokenId].redeemed); 
        string memory description = "test nft";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(descriptor.generateImage(tokenmetadata[tokenId].hash,tokenmetadata[tokenId].redeemed));
        return Base64.encode(img);
        //return descriptor.generateImage(tokenIdHash[tokenId]);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenmetadata[tokenId].hash,tokenmetadata[tokenId].redeemed);
    }


    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId);
    }

    function mint() public payable {
        require(msg.value >= 0.0001 ether, 'MORE ETH NEEDED'); //~$100
        _mint(msg.sender);
    }

    function loyalMint(bytes32[] calldata proof) public {
        loyalMintLeaf(proof, msg.sender);
    }

    // anyone can mint for someone in the merkle tree
    // you just need the correct proof
    function loyalMintLeaf(bytes32[] calldata proof, address leaf) public {
        // if one of addresses in the overlap set
        require(claimed[leaf] == false, "Already claimed");
        claimed[leaf] = true;

        bytes32 hashedLeaf = keccak256(abi.encodePacked(leaf));
        require(MerkleProof.verify(proof, loyaltyRoot, hashedLeaf), "Invalid Proof");
        _mint(leaf);
    }

    // internal mint
    function _mint(address _owner) internal {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        _createNFT(_owner);
    }

    function redeemToken(uint tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        tokenmetadata[tokenId].redeemed = true;
    }
    function _createNFT(address _owner) internal {
        uint256 tokenId = currentIndex;
        uint256 tokenHash = uint(keccak256(abi.encodePacked(block.timestamp, _owner)));
        tokenIdHash[tokenId] = tokenHash;
        tokenmetadata[tokenId].hash = tokenHash;
        currentIndex += 1;
        super._mint(_owner, tokenId);
    }

}