/**
 *Submitted for verification at Etherscan.io on 2022-07-06
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

    function generateImage(uint256 tokenId,bool redeemed, uint256 actualTokenId) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 fillI = uint256(toUint8(hash,1));
        string memory fill = 'none';
        if(fillI < 128) { fill = 'white'; }

        if (redeemed) {
            return string(
                abi.encodePacked('')
                );
        }
        
        return string(
            abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="290" height="500" fill="none" xmlns:v="https://vecta.io/nano"><style>.C{flood-opacity:0}.D{fill-rule:evenodd}.E{fill-opacity:.5}</style><g clip-path="url(#f)"><rect width="290" height="500" rx="40" fill="#000"/><rect width="290" height="500" rx="40" fill="url(#J)" fill-opacity=".2"/><g filter="url(#B)"><use xlink:href="#h" fill="url(#K)"/></g><g filter="url(#C)"><path d="M375 86c0-65.722-53.278-119-119-119h0c-65.722 0-119 53.278-119 119h0c0 65.722 53.278 119 119 119h0c65.722 0 119-53.278 119-119h0z" fill="url(#L)"/></g><rect x="24" y="439" width="137" height="29" rx="8" fill="#000" class="E"/><text x="35" y="456" fill="#fff" font-size=".89em" fill-opacity=".7" font-weight="normal" font-family="monospace">Asset ID:</text><rect x="208" y="431" width="48" height="45.083" rx="6.874" fill="#000" class="E"/><path d="M249.101 446.115a1.18 1.18 0 0 1-.223.712c-.149.207-.361.36-.605.436-.252.082-.526.07-.7',
'71-.033a1.11 1.11 0 0 1-.563-.529c-.097-.208-.146-.435-.141-.665v-5.146-.594h-.229-.371l-12.51-.076h-2.372c-.2-.021-.396-.075-.578-.16a1.93 1.93 0 0 1-.448-.298c-.145-.188-.221-.42-.215-.658-.002-.034-.002-.069 0-.103.011-.261.109-.511.279-.709a1.16 1.16 0 0 1 .492-.306 1.51 1.51 0 0 1 .493-.098c.674-.042 1.758.022 1.881.029l11.653.126c1.738-.086 3.004-.052 3.341.039.205.05.396.147.557.284.064.063.121.133.17.209a1.59 1.59 0 0 1 .177.906l-.017 6.634z" fill="url(#M)"/><path d="M217.243 466.709h.593l7.277.013c.366.001.725.101 1.039.288.194.131.337.326.404.55s.057.464-.032.681a1.07 1.07 0 0 1-.406.578c-.196.142-.435.212-.677.2h-1.571-7.602c-.921 0-1.342-.409-1.342-1.32v-6.764c-.011-.272.073-.54.238-.757a1.18 1.18 0 0 1 .663-.435c.266-.065.546-.032.789.095s.432.337.531.592c.068.204.098.418.091.633v5.097l.005.549z" fill="url(#N)"/><g stroke-width=".368" stroke-miterlimit="10"><path d="M214.874 438.255H221.479C222.688 438.225 223.893 438.391 225.049 438.747C225.876 439 226.634 439.439 227.26',
'5 440.03C227.789 440.547 228.175 441.186 228.388 441.889C228.605 442.608 228.713 443.355 228.709 444.106C228.712 444.901 228.605 445.692 228.388 446.457C228.18 447.199 227.789 447.876 227.251 448.427C226.626 449.039 225.867 449.497 225.034 449.764C223.903 450.124 222.719 450.291 221.533 450.257H218.056V457.347H214.874V438.255ZM221.451 447.533C222.133 447.549 222.813 447.466 223.471 447.287C223.934 447.162 224.36 446.928 224.714 446.605C225.013 446.317 225.229 445.954 225.34 445.554C225.462 445.1 225.52 444.632 225.515 444.162C225.522 443.688 225.459 443.215 225.327 442.759C225.209 442.369 224.982 442.021 224.672 441.756C224.303 441.461 223.874 441.251 223.414 441.141C222.762 440.983 222.092 440.911 221.422 440.926H218.056V447.533H221.451Z" fill="url(#O)" stroke="url(#P)"/><path d="M230.075 450.107H234.015L239.433 465.296L245.02 450.107H248.818V469.199H245.863V455.323L240.607 469.199H238.044L232.991 455.357V469.209H230.075V450.107Z" fill="url(#Q)" stroke="url(#R)"/></g><g filter="url(#',
'D)"><rect x="24" y="105" width="240" height="311" rx="20" fill="url(#S)"/></g><rect x="24.5" y="105.5" width="239" height="310" rx="19.5" stroke="url(#T)"/><mask id="A" maskUnits="userSpaceOnUse" x="24" y="105" width="240" height="311" mask-type="alpha"><path d="M264 125c0-11.046-8.954-20-20-20H44c-11.046 0-20 8.954-20 20v271c0 11.046 8.954 20 20 20h200c11.046 0 20-8.954 20-20V125z" fill="#000"/></mask><g mask="url(#A)"><g filter="url(#E)"><path d="M212 222.5C212 157.607 159.393 105 94.5 105h0C29.607 105-23 157.607-23 222.5v27C-23 314.393 29.607 367 94.5 367h0c64.893 0 117.5-52.607 117.5-117.5v-27z" fill="url(#U)" fill-opacity=".8"/></g><g filter="url(#F)" class="E"><path d="M381 336.5c0-64.893-52.607-117.5-117.5-117.5h0C198.607 219 146 271.607 146 336.5v27c0 64.893 52.607 117.5 117.5 117.5h0c64.893 0 117.5-52.607 117.5-117.5v-27z" fill="url(#V)"/></g></g><g clip-path="url(#g)"><path d="M82.404 41h9.485c7.439 0 12.461 2.501 12.461 9.764 0 6.974-4.994 10.257-12.261 10.257h-5.458v13.186',
'h-4.226V41zm9.155 16.608c5.807 0 8.574-2.106 8.574-6.83s-2.943-6.351-8.778-6.351h-4.724v13.181h4.928z" fill="url(#W)"/><path d="M115.964 60.495V41h4.227v19.611c0 7.978 3.37 10.489 7.708 10.489s7.872-2.511 7.872-10.489V41h4.05v19.495c0 10.657-5.143 14.32-11.922 14.32s-11.935-3.664-11.935-14.32z" fill="url(#X)"/><path d="M153.797 41h10.401c6.765 0 11.623 2.427 11.623 9.345 0 6.635-4.854 9.824-11.623 9.824h-6.175v14.037h-4.226V41zm9.796 15.743c5.166 0 8.011-2.092 8.011-6.398s-2.845-5.919-8.011-5.919h-5.579v12.316h5.579zm-.227 2.269l3.31-2.185 10.113 17.38H172l-8.634-15.194z" fill="url(#Y)"/><path d="M185.585 70.631h22.011v3.575h-22.011v-3.575zM186.087 41h20.997v3.575h-20.997V41zm3.283 13.981h14.436v3.575h-14.432l-.004-3.575z" fill="url(#Z)"/></g><g filter="url(#G)"><path d="M199.456 260.942L144 135 90.538 260.952l-.034.015.014.032-.017.04.044.019L146 385l53.462-123.952.035-.015-.014-.032.017-.04-.044-.019z" fill="url(#a)" class="D"/><path d="M193.76 260.429l-52.804-117.5-50.905 117.51-.0',
'33.014.013.03-.016.039.042.018 52.804 117.5 50.904-117.51.033-.015-.013-.03.016-.038-.041-.018z" fill="url(#b)" class="D"/><path d="M93.053 267.224l52.953 37.5 50.874-37.778 3.189-5.427-3.622-7.242-.447-.777-52.006-34.105L94 253.5h-.947l-3.053 7 3.053 6.724z" fill="url(#c)"/><path d="M143.487 219L92.5 254.145 145.506 292l50.994-37.86-.599-.806L143.487 219z" fill="url(#d)" class="D"/><path d="M143.481 219l-50.397 34.328-.584.817 53 37.855-2.019-73z" fill="url(#e)" class="D"/></g></g><text x="105" y="456" fill="#fff" font-family="monospace">',
toString(actualTokenId),
'</text><defs><filter id="B" x="-141" y="241" width="438" height="438" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="50"/></filter><filter id="C" x="37" y="-133" width="438" height="438" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="50"/></filter><filter id="D" x="23" y="105" width="241" height="312" filterUn',
'its="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic" result="B"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="C"/><feOffset dx="-1" dy="1"/><feGaussianBlur stdDeviation="10"/><feComposite in2="C" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0.85098 0 0 0 0 0.85098 0 0 0 0 0.85098 0 0 0 0.35 0"/><feBlend in2="B"/></filter><filter id="E" x="-123" y="5" width="435" height="462" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="50"/></filter><filter id="F" x="46" y="119" width="435" height="462" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="50"/></filter><filter id="G" x="80" y="126" width="130.069" height="270" filterUnits="userSpaceOnUse" class="B"><feFlood result="A" class="C"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1',
'27 0" result="B"/><feOffset dy="1"/><feGaussianBlur stdDeviation="5"/><feComposite in2="B" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35 0"/><feBlend in2="A"/><feBlend in="SourceGraphic"/></filter><filter id="H" x="95.994" y="261.545" width="44.975" height="35.532" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic" result="B"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="C"/><feOffset/><feGaussianBlur stdDeviation=".5"/><feComposite in2="C" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="B"/></filter><filter id="I" x="157.793" y="267.278" width="27.98" height="22.485" filterUnits="userSpaceOnUse" class="B"><feFlood class="C"/><feBlend in="SourceGraphic" result="B"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="C"/><feOffset/><feGaussianBlur stdDeviation=".',
'5"/><feComposite in2="C" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="B"/></filter><linearGradient id="J" x1="145" y1="0" x2="145" y2="500" xlink:href="#i"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="K" x1="179.825" y1="518.887" x2="-68.436" y2="399.68" xlink:href="#i"><stop stop-color="#3c3c3c" stop-opacity=".37"/><stop offset="1" stop-color="#3c3c3c"/></linearGradient><linearGradient id="L" x1="357.825" y1="144.887" x2="109.564" y2="25.68" xlink:href="#i"><stop stop-color="#3c3c3c" stop-opacity=".37"/><stop offset="1" stop-color="#3c3c3c"/></linearGradient><linearGradient id="M" x1="230.075" y1="442.591" x2="249.121" y2="442.591" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="N" x1=',
'"214.923" y1="464.372" x2="226.593" y2="464.372" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="O" x1="214.874" y1="447.799" x2="228.699" y2="447.799" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="P" x1="214.751" y1="447.799" x2="228.822" y2="447.799" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="Q" x1="230.075" y1="459.654" x2="248.82" y2="459.654" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=',
'".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="R" x1="229.952" y1="459.654" x2="248.943" y2="459.654" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><radialGradient id="S" cx="0" cy="0" r="1" gradientTransform="translate(144 260.5) rotate(90) scale(155.5 120)" xlink:href="#i"><stop stop-color="#3c3c3c"/><stop offset="1"/></radialGradient><linearGradient id="T" x1="246" y1="105" x2="24" y2="416" xlink:href="#i"><stop stop-color="#3c3c3c"/><stop offset="1" stop-color="#3c3c3c" stop-opacity="0"/></linearGradient><linearGradient id="U" x1="195.041" y1="300.825" x2="-59.41" y2="191.236" xlink:href="#i"><stop stop-color="#e94057" stop-opacity=".37"/><stop offset="1" stop-color="#e94057"/></linearGradient><linearGradient id="V" x1="364.041" y1="414.825" x2="109.59" y2="305.236" xlink:href="#i"><stop stop-color="#0ff" stop-opacity=".37"/><stop offset="1" stop-color="#8a2387"/></linearGradient><linearGradient id="W" x1="82.404" y1="57.603" x2="104.35" y2="57.603" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="X" x1="115.964" y1="57.905" x2="139.821" y2="57.905" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="Y" x1="153.797" y1="57.603" x2="176.807" y2="57.603" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7',
'a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="Z" x1="185.585" y1="57.603" x2="207.596" y2="57.603" xlink:href="#i"><stop stop-color="#ce9728"/><stop offset=".16" stop-color="#875b11"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="a" x1="148.247" y1="146.568" x2="139.265" y2="324.474" xlink:href="#i"><stop stop-color="#8a4703"/><stop offset=".229" stop-color="#ffff73"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".734" stop-color="#e79728"/><stop offset="1" stop-color="#8a4703"/></linearGradient><linearGradient id="b" x1="145" y1="152" x2="103.5" y2="323" xlink:href="#i"><stop offset=".13" stop-color="#8a4703"/><stop offset=".281" stop-color="#e79728"/><stop offset=".41" stop-color="#ffec7a"/><stop offset=".85" stop-color="#ffff73"/><stop offset="1" stop-color="#e79728"/></linearGradient><radialGradient id="c" cx="0" cy="0" r="1" gradientTransform="translate(202.5 231.5) rotate(164.503) scale(114.15 147.319)" xlink:href="#i"><stop stop-color="#ffec7a"/><stop offset=".313" stop-color="#ffff73"/><stop offset=".75" stop-color="#ffff73"/><stop offset="1" stop-color="#ffec7a"/></radialGradient><linearGradient id="d" x1="154.536" y1="265.782" x2="138.979" y2="303.427" xlink:href="#i"><stop stop-color="#8a4703"/><stop offset=".404"/><stop offset="1" stop-color="#e79728"/></linearGradient><linearGradient id="e" x1="132.946" y1="237.676" x2="118.893" y2="271.806" xlink:href="#i"><stop stop-color="#8a4703"/><stop offset=".781" stop-color="#ce9728"/><stop offset="1" stop-color="#e79728"/></linearGradient><clipPath id="f"><rect width="290" height="500" rx="40" fill="#fff"/></clipPath><clipPath id="g"><path fill="#fff" transform="translate(82.404 41)" d="M0 0h125.191v33.815H0z"/></clipPath><path id="h" d="M197 460c0-65.722-53.278-119-119-119h0c-65.722 0-119 53.278-119 119h0c0 65.722 53.278 119 119 119h0c65.722 0 119-53.278 119-119h0z"/><linearGradient id="i" gradientUnits="userSpaceOnUse"/></defs></svg>')
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
        bytes memory img = bytes(descriptor.generateImage(tokenmetadata[tokenId].hash,tokenmetadata[tokenId].redeemed,tokenId));
        return Base64.encode(img);
        //return descriptor.generateImage(tokenIdHash[tokenId]);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenmetadata[tokenId].hash,tokenmetadata[tokenId].redeemed,tokenId);
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