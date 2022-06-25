/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT

/*
Contract that's primarily responsible for generating the metadata, including the image itself in SVG.
Parts of the SVG is encapsulated into custom re-usable components specific to this collection.
*/

/*
Little Martians have the following randomised components.

1) 1 of 10 hardcoded shells.
2) Degree of blur + random seed. 
3) Step pattern with 2 vars + random seed.
4) Background pattern
5) Foreground pattern with colour shifting + alpha slope
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

    function generateName(uint nr) public pure returns (string memory) {
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

    function generateImage(uint256 tokenId) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillI = uint256(toUint8(hash,1));
        string memory fill = 'none';
        if(fillI < 128) { fill = 'white'; }
        return string(
            abi.encodePacked('<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"  viewBox="0 0 612 792" style="enable-background:new 0 0 612 792;" xml:space="preserve"><style type="text/css">  .st0{clip-path:url(#SVGID_00000058574021165109556420000003985137933947389575_);}  .st1{fill:#FFFFFF;} .st2{fill:#E9E0A1;}</style><g>  <g>   <defs>      <path id="SVGID_1_" d="M182.82,122.68c0,3.24,0,6.48,0,9.71c0,154.28,0,308.56,0,462.84c0,4.32,0,8.65,0,12.97       c20.65,3.12,42.34,5.66,64.99,7.42c76.86,5.96,146.12,1.4,205.17-7.42c1.7-161.84,3.4-323.68,5.1-485.52        c-77.69-9.16-161.36-11.4-249.77-2.77C199.74,120.74,191.24,121.67,182.82,122.68z"/>    </defs>   <clipPath id="SVGID_00000091004766685754875480000001483152757838229162_">     <use xlink:href="#SVGID_1_"  style="overflow:visible;"/>    </clipPath>   <g style="clip-path:url(#SVGID_00000091004766685754875480000001483152757838229162_);">    </g>  </g></g><rect x="238.89" y="202.73" class="st1" width="163.12" height="281.63"/><polygon class="st2" points="320.98,241.07 247.18,347.49 247.18,358.75 320.98,446.03 393.73,358.75 393.73,344.5 "/><path class="st1" d="M758.82,469.07"/><g>  <g>   <path d="M243.79,529.65h9.5c6.96,0,11.67,2.35,11.67,9.26c0,6.67-4.75,9.74-11.67,9.74h-5.47v12.48h-4.03V529.65z M252.81,545.39     c5.47,0,8.11-2.02,8.11-6.48c0-4.51-2.69-6-8.11-6h-4.99v12.48H252.81z"/>   <path d="M286.85,549.23v-19.58h4.08v19.68c0,6.48,2.83,8.83,6.58,8.83c3.79,0,6.67-2.35,6.67-8.83v-19.68h3.89v19.58     c0,9.03-4.42,12.48-10.56,12.48C291.31,561.71,286.85,558.26,286.85,549.23z"/>    <path d="M331.96,529.65h9.84c6.38,0,11.04,2.3,11.04,8.88c0,6.29-4.66,9.31-11.04,9.31h-5.76v13.3h-4.08V529.65z M341.23,544.58      c4.9,0,7.58-2.02,7.58-6.05c0-4.13-2.69-5.62-7.58-5.62h-5.18v11.67H341.23z M344.16,544.62l9.6,16.51h-4.56l-8.21-14.4     L344.16,544.62z"/>    <path d="M374.73,557.73h22.08v3.41h-22.08V557.73z M375.21,529.65h21.12v3.41h-21.12V529.65z M378.33,542.9h14.88v3.41h-14.88      V542.9z"/>  </g></g></svg>')

        );
    }

    function generatePath(bytes memory hash) public pure returns (string memory) {
        uint256 index = uint256(toUint8(hash,0))*100/256; // 0 - 100
        string memory path;

        if(index < 10) { path = "M189 49c-23 7-35 24-40 32-12 16-15 31-17 41-6 26 1 29-2 73-1 13-2 21-1 35s4 26 5 33l14 42 11 28 6 12c1 3 5 11 18 27l13 15c14 9 29 6 31 5 9-2 15-7 20-11 10-8 15-17 24-35 6-10 9-16 11-23 6-17 2-20 8-35 6-14 11-13 14-26 2-8 1-11 4-21 3-8 5-9 5-15 0-7-2-8-4-17-2-11 1-13 0-27-2-11-4-12-3-17 2-9 8-11 11-19 4-10 0-21-2-27-2-4-3-6-22-30l-16-18c-4-3-10-9-19-14-3-2-13-7-27-10-8-1-24-4-42 2z"; }
        else if(index < 20) { path = "M240 23c17 3 25 5 35 11 13 8 19 17 29 33a197 197 0 0135 106c2 21 2 31 0 40-3 9-8 16-10 31l-2 14c0 4-3 18-10 31-3 7-9 13-22 27-13 12-17 15-21 24-3 6-2 9-6 15-4 7-8 12-14 17-9 10-11 9-22 19-9 9-8 10-14 14-8 6-17 9-25 10-14 1-25-7-45-23-10-8-40-32-43-57l-1-11-3-29c-3-22-8-23-9-37 0-13 3-13 7-38 4-20 1-21 5-53 3-24 4-20 5-34 1-22-1-32 4-48l8-18c2-3 8-14 20-25 6-5 20-17 41-22 18-5 33-2 58 3z"; }
        else if(index < 30) { path = "M188 21c3-1 43 1 60 4 33 6 70 47 79 65 2 5 17 60 17 81 0 15-4 3-4 44 0 24-6 40-16 61-9 26-7 34-18 60a113 113 0 01-50 63c-12 7-23 14-40 13-18-1-33-17-37-24-21-37-41-65-45-73-3-8-21-33-25-67-1-12 5-37 4-56-1-29-7-39-4-50 8-26 6-16 11-42 4-20 8-52 26-64 15-12 32-14 42-15z"; }
        else if(index < 40) { path = "M71 93v21l1 24c3 22 5 23 9 48l2 13c4 12 13 20 15 23 9 8 21 30 45 74 9 18 13 26 22 36 9 8 16 13 27 20 18 12 45 28 78 32a57 57 0 0049-18c8-9 11-18 16-37 6-21 9-31 6-40-2-6-5-10-6-18l2-18c2-10 6-26 5-42 0-14-5-26-7-33l-10-22c-6-18-2-21-8-32-5-9-8-9-17-22-8-12-9-18-14-25-9-17-23-25-38-33-35-20-69-20-82-19-15 1-36 2-58 16-3 2-35 24-37 52z"; }
     
        return string(abi.encodePacked(
            '<clipPath id="m"> <path d="',path,'"/></clipPath>'
        ));
    }

    function generateFace(bytes memory hash) public pure returns (string memory) {
        uint256 index = uint256(toUint8(hash,0))*100/256; // 0 - 100
        string memory path;

        if(index < 10) { path = "M182 223c0-3-4-5-7-6-5-1-8 1-14 3-12 4-19 2-19 4s8 6 17 6c11 1 23-3 23-7zM235 227c0-2 9-5 14-6s11-2 18-1c7 2 16 7 15 10 0 3-9 3-10 4-7 0-10-2-18-4-12-3-18-1-19-3z M241 300c0 2-3 3-4 3-13 6-10 8-21 12-7 3-15 5-25 4-4 0-12-1-18-7-6-5-10-14-10-14 13-9 16-15 16-15l3-6c4-10 2-11 5-19l5-11v-2c6-16 3-31 3-31-1-3-3-14-10-19l-2-2a39 39 0 00-15-5c-2-1-9-2-16 0-8 1-11 4-13 3-1-1 1-8 6-12 8-7 20-4 27-2 5 1 12 2 19 8a40 40 0 0114 31v19c-2 12-2 18-6 26l-5 10c-12 21-14 25-12 29 1 6 7 9 8 10 11 4 23-4 24-5 9-6 9-13 15-14 6 0 12 5 12 9z M174 338c1-2 3-1 27-2h14c4 2 6 4 9 3s2-5 5-7c4-3 7-1 14 1 12 2 17 0 18 1 1 4-15 14-32 19-8 3-16 5-25 4-17-3-31-15-30-19z"; }
        else if(index < 20) { path = "M326 200c-1 1-9-6-29-12-23-7-32-5-35-4-3 0-11 3-18 10a38 38 0 00-10 26c0 6 2 6 5 18 1 4 4 16 5 31 1 13-1 13 1 21s5 11 5 18c-1 2-1 8-5 13-7 10-21 10-22 10-10 0-9-5-28-12-9-3-25-11-24-18 1-4 10-12 7-12l8 13c6 9 16 17 27 18 7 1 19 0 24-7 3-7-2-12-6-30s0-17-4-48c-2-13-4-19-2-28 1-5 3-14 11-21 6-5 21-14 40-11 28 5 51 23 50 25zM131 175c16-14 51-8 60-3 3 2 0 1 0 0 0 0-3-9-18-13-4-2-19-2-31 7-6 4-9 6-11 9zM125 210c2-5 20-5 33-3 3 0 16 0 22 11l1 6c1 8 3 10 3 10-4 1-9-5-17-8h-16c-13 0-27-10-26-16z M257 236c0-5 14-10 26-10 19 1 36 14 34 17 0 2-3 1-13 3l-18 3c-13 0-29-7-29-13zM151 355c1-2 5 2 15 4 11 1 21-1 24-1 7-2 10-4 14-2 5 2 5 7 9 7s6-6 12-7l8 2c11 4 20 0 20 1 1 2-10 13-32 21-10 4-14 2-20 2-11 1-20-2-23-4-17-7-27-23-27-23z"; }
        else if(index < 30) { path = "M152 205s25 10 37 1c3-2-5-9-8-11-7-3-10-6-14-5-12 2-17 12-15 15zM265 214c-2-2 6-9 17-14 5-2 9-2 11-2 13 0 21 12 21 12 0 3-9 4-10 4-8 2-7-3-15-4-13-2-22 6-24 4zM191 289c-3 1-6 8-3 13s10 6 14 9c2 1 6 4 15 4 6-1 6-4 13-6l14-4c7-2 10-3 10-8s-5-9-5-9 2 7-1 12c-3 4-11 2-19 5-11 5-8 6-18 5-7 0-17-4-21-8-3-3 1-13 1-13zM184 351c-1 1 10 11 26 16l13 2c3 0 10 0 18-5 6-3 12-9 11-11s-8 1-21 4c-8 2-17 3-26 2-13-2-21-9-21-8zM252 175c1 1 10-10 25-12 13-3 26 2 28 3 7 3 12 7 13 6 1-2-4-9-11-14-14-9-32-2-34-1-14 6-21 17-21 18zM144 168c1 2 14-12 30-10 18 2 17 13 26 9 0 0 1-3-4-7-11-5-15-11-34-4-11 4-20 10-18 12zM213 215c1-5 3 27 2 38l-5 18c-1 4-5 5-5 5 2-4 4-6 6-16 2-17 1-40 2-45z"; }
        else if(index < 40) { path = "M159 239c0-2 7 0 14-4l4-4 6-7 5-11s4 6 4 11c1 7-5 16-14 19s-19-3-19-4zM270 199c-1-2 6-9 13-12l10-3c7-5 8-12 10-11 2 0 3 9 0 15-4 5-9 7-18 9-4 1-14 4-15 2zM134 218c1 0 3-9 13-16l1-2 16-7c13-5 12-12 21-13 7-1 12 1 12 1s-8-6-15-6c-8 0-8 3-21 10-10 6-9 1-15 6-10 9-13 27-12 27z M305 141s-11-9-23-6c-3 1-5 2-21 18l-13 14c-4 6-11 14-12 26-2 16 7 30 17 45l10 13 2 2 10 10c8 6 16 9 17 9 5 2 7 2 7 4 1 2-3 5-8 9-10 10-8 14-14 18l-20 2c-8 1-8 2-12 1-6-1-15-5-14-7l14 3c14 2 28-3 29-4 7-7 12-14 13-18 1-6-12-3-26-17-6-6-12-12-17-20-9-13-12-24-13-27-4-16-2-28-2-31 1-10 5-16 13-24 5-5 5-9 15-17s10-10 14-12c15-6 34 8 34 9zM245 345s7-11 15-14c4-2 5-1 14-3 7-2 10-3 14-6l8-9c6-7 6-9 9-10 3-2 9-6 11-4 2 1 2 3 0 16l-4 16c-5 8-12 11-18 14-8 3-14 4-19 4-9 1-30-4-30-4z"; }
   
        return string(abi.encodePacked(
            '<path class="c" d="',path,'"/>'
        ));
    }

    function generateBlur(bytes memory hash) public pure returns (string memory) {
        uint256 blurDegree = uint256(toUint8(hash,2))/64; // 1 - 4
        uint256 blurSeed = uint256(toUint8(hash,3));

        return string(abi.encodePacked(
            svgFilter('blur'), 
            '<feTurbulence baseFrequency="',generateDecimalString(5,blurDegree+1),'" seed="',toString(blurSeed),'" result="turbs"/>',
            '<feSpecularLighting surfaceScale="200" result="out" specularExponent="20">',
            '<fePointLight x="216" y="17" z="200"/>',
            '</feSpecularLighting>',
            '<feGaussianBlur in="out" stdDeviation="4" result="blurred"/>',
            '<feComposite in="SourceGraphic" in2="blurred" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>',
            '</filter>'
        ));
    }

    function generateSteps(bytes memory hash) public pure returns (string memory) {
        uint256 stepsDegree = uint256(toUint8(hash,4))/64; // 1 - 4
        uint256 stepsInterDegree = 1+uint256(toUint8(hash,5))*100/256/10;
        uint256 stepsSeed = uint256(toUint8(hash,6));
        uint256 stepsScale = 80+uint256(toUint8(hash,7))/2;
        return string(abi.encodePacked(
            svgFilter('steps'), 
            '<feTurbulence baseFrequency="',generateDecimalString(stepsInterDegree,stepsDegree+1),'" seed="',toString(stepsSeed),'" result="turbs"/>',
            '<feSpecularLighting surfaceScale="',toString(stepsScale),'" result="specOut" specularExponent="20">',
            '<fePointLight x="210" y="17" z="200"/>',
            '</feSpecularLighting>',
            '<feComposite in="SourceGraphic" in2="blurred" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>',
            '</filter>'
        ));
    }

    function generateTurbs1(bytes memory hash) public pure returns (string memory) {
        uint256 turbs1Degree = uint256(toUint8(hash,8))/128; // 0 - 2 (2 is very slightly rarer due to it ending at 2.965)
        uint256 turbs1InterDegree = 1+uint256(toUint8(hash,9))*100/256/10;
        uint256 turbs1Seed = uint256(toUint8(hash,10));
        return string(abi.encodePacked(
            svgFilter('turb1'), 
            '<feTurbulence baseFrequency="',generateDecimalString(turbs1InterDegree,turbs1Degree+2),'" seed="',toString(turbs1Seed),'" result="turbs"/>',
            '</filter>'
        ));
    }

    function getColourOffset(bytes memory hash, uint256 hashIndex) public pure returns (string memory) {
        uint256 shift = uint256(toUint8(hash,hashIndex))/128; // 0 or 1. Positive or Negative
        uint256 change = uint256(toUint8(hash,hashIndex))*100/256; // 0 - 99 
        string memory sign = "";
        if(shift == 1) { sign = "-"; }
        return string(abi.encodePacked(
            sign,generateDecimalString(change,1)
        ));
    }

    function svgRect(string memory opacity, string memory filter, string memory fill) public pure returns (string memory) {
        return string(abi.encodePacked('<rect width="100%" height="200%" clip-path="url(#m)" opacity="',opacity,'" filter="url(#',filter,')" fill="',fill,'"/>'));
    }

    function svgFilter(string memory id) public pure returns (string memory) {
        return string(abi.encodePacked('<filter id="',id,'" width="100%" height="100%">'));
    }

    function svgFeTurbulence(string memory seed, string memory baseFrequency) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<feTurbulence type="turbulence" seed="',seed,'" baseFrequency="',baseFrequency,'" result="turbs"/>'
        ));
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

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.

    address public collector; // address authorised to withdraw funds recipient
    address payable public recipient; // in this instance, it will be a mirror split on mainnet (to be deployed)

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    CollectionDescriptor public descriptor;

    mapping (address => bool) public claimed;
    mapping (uint => uint) public tokenIdHash;
    bytes32 private loyaltyRoot;


    uint public currentIndex = 1;

    // todo: for testing
    // uint256 public newlyMinted;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address payable recipient_) ERC721(name_, symbol_) {
        collector = address(msg.sender); 
        recipient = recipient_;
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

        string memory name = descriptor.generateName(tokenId); 
        string memory description = "test nft";

        string memory image = generateBase64Image(tokenIdHash[tokenId]);
        string memory attributes = generateTraits(tokenIdHash[tokenId]);
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
        bytes memory img = bytes(generateImage(tokenIdHash[tokenId]));
        return Base64.encode(img);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenIdHash[tokenId]);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenIdHash[tokenId]);
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

    function _createNFT(address _owner) internal {
        uint256 tokenId = currentIndex;
        uint256 tokenHash = uint(keccak256(abi.encodePacked(block.timestamp, _owner)));
        tokenIdHash[tokenId] = tokenHash;
        currentIndex += 1;
        super._mint(_owner, tokenId);
    }

}