// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gorbitz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                        ___.   .__  __                                                                                                                                           //
//       ____   __________\_ |__ |__|/  |_________                                                                                                                                 //
//      / ___\ /  _ \_  __ \ __ \|  \   __\___   /                                                                                                                                 //
//     / /_/  >  <_> )  | \/ \_\ \  ||  |  /    /                                                                                                                                  //
//     \___  / \____/|__|  |___  /__||__| /_____ \                                                                                                                                 //
//    /_____/                  \/               \/                                                                                                                                 //
//                                                                                                                                                                                 //
//    import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";                                                                                                              //
//    import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";                                                                                         //
//    import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";                                                                                           //
//    import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Royalty.sol";                                                                                            //
//                                                                                                                                                                                 //
//    import "@openzeppelin/[email protected]/access/Ownable.sol";                                                                                                                   //
//    import "@openzeppelin/[email protected]/utils/Counters.sol";                                                                                                                   //
//    import "@openzeppelin/[email protected]/finance/PaymentSplitter.sol";                                                                                                          //
//    import "./library/Base64.sol";                                                                                                                                               //
//                                                                                                                                                                                 //
//    }                                                                                                                                                                            //
//                                                                                                                                                                                 //
//    contract gOrbitz is ERC721, ERC721Enumerable, ERC721Burnable, ERC721Royalty, Ownable {                                                                                       //
//        using Counters for Counters.Counter;                                                                                                                                     //
//                                                                                                                                                                                 //
//        Counters.Counter private _tokenIdCounter;                                                                                                                                //
//                                                                                                                                                                                 //
//        uint256 public constant MAX_TOKENS = 100;                                                                                                                                //
//                                                                                                                                                                                 //
//        uint256 public constant MAX_TOKENS_PER_SALE = 1;                                                                                                                         //
//                                                                                                                                                                                 //
//        uint256 public price = 0 ether;                                                                                                                                          //
//                                                                                                                                                                                 //
//        string[] private colors = [ "#FFF", "#FFF", "#FFF", "#FFF", "rgba(255,255,255,0.95)", "rgba(0,0,200,0.95)", "#00A", "#B00" ];                                            //
//                                                                                                                                                                                 //
//        uint256[] private o0 = [uint256(28), 40, 52, 64, 76, 88, 100];                                                                                                           //
//        uint256[] private o1 = [uint256(30), 44, 58, 72, 86, 100];                                                                                                               //
//        uint256[] private o2 = [uint256(28), 46, 64, 82, 100];                                                                                                                   //
//        uint256[] private o3 = [uint256(32), 54, 77, 100];                                                                                                                       //
//        uint256[] private o4 = [uint256(30), 75, 100];                                                                                                                           //
//        uint256[] private o5 = [uint256(35), 100];                                                                                                                               //
//                                                                                                                                                                                 //
//        bool public isSaleActive = true;                                                                                                                                         //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//        constructor() ERC721("gOrbitz", "GORBZ") payable {                                                                                                                       //
//            _setDefaultRoyalty(address(this), 500);                                                                                                                              //
//            turnstile.register(msg.sender);                                                                                                                                      //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function getColor(uint256 tokenId) internal view returns (string memory) {                                                                                               //
//            uint256 rand = random(string.concat("C", toString(tokenId)), colors.length);                                                                                         //
//            return colors[rand];                                                                                                                                                 //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function _radiuses(uint256 tokenId) internal view returns (uint256[] memory) {                                                                                           //
//            uint256 rand = random(string.concat("R", toString(tokenId)), 6);                                                                                                     //
//            if (rand == 0) return o0;                                                                                                                                            //
//            if (rand == 1) return o1;                                                                                                                                            //
//            if (rand == 2) return o2;                                                                                                                                            //
//            if (rand == 3) return o3;                                                                                                                                            //
//            if (rand == 4) return o4;                                                                                                                                            //
//            return o5;                                                                                                                                                           //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function getOrbit(uint256 radius) internal pure returns (string memory) {                                                                                                //
//            return string.concat(                                                                                                                                                //
//                '<circle cx="0" cy="0" r="',                                                                                                                                     //
//                toString(radius),                                                                                                                                                //
//                '" />'                                                                                                                                                           //
//            );                                                                                                                                                                   //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function getPlanet(uint256 orbit, uint256 planet, uint256 period, uint256 deg) internal pure returns (string memory) {                                                   //
//            return string.concat(                                                                                                                                                //
//                '<circle cx="0" cy="',                                                                                                                                           //
//                toString(orbit),                                                                                                                                                 //
//                '" r="',                                                                                                                                                         //
//                toString(planet),                                                                                                                                                //
//                '" transform="rotate(',                                                                                                                                          //
//                toString(deg),                                                                                                                                                   //
//                ' 0 0)">',                                                                                                                                                       //
//                '<animateTransform attributeName="transform" begin="0s" dur="',                                                                                                  //
//                toString(period),                                                                                                                                                //
//                's" type="rotate" from="0 0 0" to="360 0 0" repeatCount="indefinite" /></circle>'                                                                                //
//            );                                                                                                                                                                   //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function planets(uint256 tokenId) internal view returns (string memory) {                                                                                                //
//            uint256 rand = random(string(abi.encodePacked("P", toString(tokenId))));                                                                                             //
//            uint256 num = rand % 16;                                                                                                                                             //
//            uint256[] memory radiuses = _radiuses(tokenId);                                                                                                                      //
//            string memory res = '';                                                                                                                                              //
//            uint256 deg = 360 / (radiuses.length + 1);                                                                                                                           //
//                                                                                                                                                                                 //
//            for (uint8 i = 0; i < radiuses.length; i++) {                                                                                                                        //
//                res = string.concat(res, getPlanet(                                                                                                                              //
//                    radiuses[i],                                                                                                                                                 //
//                    ((rand >> 8) % 15) + 2,                                                                                                                                      //
//                    ((rand >> 16) % 36) + 4,                                                                                                                                     //
//                    deg * i                                                                                                                                                      //
//                ));                                                                                                                                                              //
//                rand = rand >> 16;                                                                                                                                               //
//            }                                                                                                                                                                    //
//            if (num > radiuses.length) {                                                                                                                                         //
//                for (uint8 i = 0; i < num - radiuses.length; i++) {                                                                                                              //
//                    res = string.concat(res, getPlanet(                                                                                                                          //
//                        radiuses[i % radiuses.length],                                                                                                                           //
//                        2,                                                                                                                                                       //
//                        ((rand >> 8) % 33) + 3,                                                                                                                                  //
//                        deg * i                                                                                                                                                  //
//                    ));                                                                                                                                                          //
//                    rand = rand >> 8;                                                                                                                                            //
//                }                                                                                                                                                                //
//            }                                                                                                                                                                    //
//            return res;                                                                                                                                                          //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function orbits(uint256 tokenId) internal view returns (string memory)  {                                                                                                //
//            uint256[] memory radiuses = _radiuses(tokenId);                                                                                                                      //
//            string memory res = '';                                                                                                                                              //
//            for (uint8 i = 0; i < radiuses.length; i++) {                                                                                                                        //
//                res = string.concat(res, (getOrbit(radiuses[i])));                                                                                                               //
//            }                                                                                                                                                                    //
//            return res;                                                                                                                                                          //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function flipSaleStatus() public onlyOwner {                                                                                                                             //
//            isSaleActive = !isSaleActive;                                                                                                                                        //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function setPrice(uint256 _price) public onlyOwner {                                                                                                                     //
//            price = _price;                                                                                                                                                      //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function safeMint(uint256 _amount) public payable {                                                                                                                      //
//            require(isSaleActive, "Sale is paused");                                                                                                                             //
//            require(MAX_TOKENS >= _amount + _tokenIdCounter.current(), "Not enough tokens left to buy");                                                                         //
//            require(_amount > 0 && _amount < MAX_TOKENS_PER_SALE + 1, "Amount of tokens too big");                                                                               //
//            require(msg.value >= price * _amount, "Insufficient funds sent");                                                                                                    //
//                                                                                                                                                                                 //
//            for(uint256 i = 0; i < _amount; i++){                                                                                                                                //
//                _safeMint(msg.sender, _tokenIdCounter.current());                                                                                                                //
//                _tokenIdCounter.increment();                                                                                                                                     //
//            }                                                                                                                                                                    //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function reserveTokens(uint256 _amount) public onlyOwner() {                                                                                                             //
//            require(MAX_TOKENS >= _amount + _tokenIdCounter.current(), "Not enough tokens left");                                                                                //
//                                                                                                                                                                                 //
//            for (uint i = 0; i < _amount; i++) {                                                                                                                                 //
//                _safeMint(msg.sender, _tokenIdCounter.current());                                                                                                                //
//                _tokenIdCounter.increment();                                                                                                                                     //
//            }                                                                                                                                                                    //
//        }                                                                                                                                                                        //
//        // The following functions are overrides required by Solidity.                                                                                                           //
//                                                                                                                                                                                 //
//        function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {                                //
//            super._beforeTokenTransfer(from, to, tokenId, batchSize);                                                                                                            //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function tokenURI(uint256 tokenId)  public view override returns (string memory) {                                                                                       //
//            _requireMinted(tokenId);                                                                                                                                             //
//            string memory color = getColor(tokenId);                                                                                                                             //
//            string memory res = string.concat(                                                                                                                                   //
//                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 280"><rect x="0" y="0" height="280" width="280" fill="#000" /><g transform="translate(140, 140)">',    //
//                '<g style="stroke:', color, ';fill:none;stroke-width:0.5;">',                                                                                                    //
//                orbits(tokenId),                                                                                                                                                 //
//                '</g><g style="fill:', color, ';">',                                                                                                                             //
//                planets(tokenId),                                                                                                                                                //
//                '</g>'                                                                                                                                                           //
//                '</g></svg>'                                                                                                                                                     //
//            );                                                                                                                                                                   //
//            string memory json = Base64.encode(                                                                                                                                  //
//                bytes(string.concat(                                                                                                                                             //
//                        '{"name":"Orbitz #',                                                                                                                                     //
//                        toString(tokenId),                                                                                                                                       //
//                        '","description":"Two-dimensional worlds endlessly orbiting on Canto chain.","image":"data:image/svg+xml;base64,',                                       //
//                        Base64.encode(bytes(res)),                                                                                                                               //
//                        '"}'                                                                                                                                                     //
//                ))                                                                                                                                                               //
//            );                                                                                                                                                                   //
//                                                                                                                                                                                 //
//            return string.concat("data:application/json;base64,", json);                                                                                                         //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty)                                                                                                 //
//        {                                                                                                                                                                        //
//            super._burn(tokenId);                                                                                                                                                //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {                                           //
//            return super.supportsInterface(interfaceId);                                                                                                                         //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function toString(uint256 value) internal pure returns (string memory) {                                                                                                 //
//            if (value == 0) {                                                                                                                                                    //
//                return "0";                                                                                                                                                      //
//            }                                                                                                                                                                    //
//            uint256 temp = value;                                                                                                                                                //
//            uint256 digits;                                                                                                                                                      //
//            while (temp != 0) {                                                                                                                                                  //
//                digits++;                                                                                                                                                        //
//                temp /= 10;                                                                                                                                                      //
//            }                                                                                                                                                                    //
//            bytes memory buffer = new bytes(digits);                                                                                                                             //
//            while (value != 0) {                                                                                                                                                 //
//                digits -= 1;                                                                                                                                                     //
//                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));                                                                                                        //
//                value /= 10;                                                                                                                                                     //
//            }                                                                                                                                                                    //
//            return string(buffer);                                                                                                                                               //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function withdraw() external onlyOwner {                                                                                                                                 //
//           payable(msg.sender).transfer(address(this).balance);                                                                                                                  //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function random(string memory input) internal pure returns (uint256) {                                                                                                   //
//            return uint256(keccak256(abi.encodePacked(input)));                                                                                                                  //
//        }                                                                                                                                                                        //
//                                                                                                                                                                                 //
//        function random(string memory input, uint256 mod) internal pure returns (uint256) {                                                                                      //
//            return uint256(keccak256(abi.encodePacked(input))) % mod;                                                                                                            //
//        }                                                                                                                                                                        //
//    }                                                                                                                                                                            //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract gorbz is ERC721Creator {
    constructor() ERC721Creator("gorbitz", "gorbz") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        (bool success, ) = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}