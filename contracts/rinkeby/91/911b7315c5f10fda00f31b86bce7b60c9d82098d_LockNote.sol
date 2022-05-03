//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721_address_specific} from './ERC721_address_specific.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';
import {utils} from './Utils.sol';
import {WordWrap} from './WordWrap.sol';

contract LockNote is ERC721_address_specific {
    
    uint256 constant MAX_MESSAGE = 280;
    uint256 MESSAGE_PRICE = 0.0042069 ether;
    address payable public deployer; 

    constructor () 
        ERC721_address_specific("Scrolls", unicode"📜")
        {
            deployer = payable(msg.sender);
            // do initial mint
            uint256 _id = getIdfromAddress(msg.sender);
            messages[_id].text = 'we shall now get ready to write some scrolls';
            messages[_id].sender = msg.sender;
            _mint(msg.sender, _id);
        }

    struct MESSAGE {
        string text;
        address sender;
    }

    mapping (uint256 => MESSAGE) public messages;



    function tokenURI(uint256 id) public view override returns (string memory) {
        require(ownerOf(id) == getAddressfromId(id), "NOT MINTED");
        MESSAGE memory _message = messages[id];

        WordWrap.WordWrapInfo memory bodyTextFormatting = WordWrap.WordWrapInfo({
            line_width: 38,
            x: 35,
            yFirst: 45,
            spacing: 20 
        });

        return json.formattedMetadata(
            'Scrolls',
            'Scrolls is an NFT based messaging application. Users can mint a message up to 280 characters long to any address, which can only be burned by the owner of that address. Have fun with Lock Note however you like.',
            svg._svg(
                    'viewBox="0 0 350 300"',
                    string.concat(
                        '<defs><linearGradient id="a" x1="25" x2="-.1" y1="142" y2="142" gradientUnits="userSpaceOnUse"><stop stop-color="#8d5c34" offset=".1"/><stop stop-color="#e8d0a9" offset=".3"/><stop stop-color="#e3cba4" offset=".6"/><stop stop-color="#8d5c34" offset="1"/></linearGradient><linearGradient id="b" x1="22" x2="321" y1="145" y2="135" gradientUnits="userSpaceOnUse"><stop stop-color="#8d5c34"/><stop stop-color="#d1b38b" offset=".05"/><stop stop-color="#e3cba4" offset=".95"/><stop stop-color="#8d5c34" offset="1"/></linearGradient><linearGradient id="c" x1="343" x2="316" y1="144" y2="144" gradientUnits="userSpaceOnUse"><stop stop-color="#8d5c34"/><stop stop-color="#93633b" offset=".1"/><stop stop-color="#e8d0a9" offset=".3"/><stop stop-color="#e3cba4" offset=".6"/><stop stop-color="#93633a" offset=".9"/><stop stop-color="#8d5c34" offset="1"/></linearGradient></defs><path d="m3.5 275.9c-0.2-90.2-1.4-180.4-2.7-270.5 5.6-2.8 18.6-3.7 17.2 5.2 3.6 90 7.1 180 10.7 269.9-7.9-3.2-16.6-7.5-25.2-4.6z" fill="url(#a)" fill-rule="evenodd"/><path d="m12.1 282.6-1.2-3.9-5.1-2.1c3.8-1.2 7.3-1.3 10.8-0.6 3.4 0.9 6.7 2.4 9.8 5.1-2.8 1.4-5.4 2.2-7.7 2.4-2.5 0.3-4.5-0.1-6.6-0.9z" fill="url(#a)" fill-rule="evenodd"/><path d="m28.8 276c-3.8-89.8-7.6-179.5-11.4-269.3 14.7 1.4 29.9 0.6 44.4 2.5 3.8 6.6 11.3 9.6 12.6-0.7 11-1.8 24.2-3.5 23.6 10 6.3 4.3 5.2-15.3 15.8-9.1 10.7-2.2 20 1.4 28.3 5.7 3.9-11.9 24-7.1 31.6-1.9 1.7 6.1 4.6 20.8 4.5 6.8 0.7-17.6 21.3-9.8 33.2-9.8 2.9 6.8 4.6 16.7 7.3 3.9 6.8-5.5 26.7-0.5 38.5-4.4 13.5-2.2 27.2 4 41 2.4 8.6 1.2 22-4.8 18.3 8.4 0.3 84.4 0.6 168.8 0.9 253.3-16.7-4-33.7 2.2-50.6 1.9-11.9-2.4-33.1 7.7-36.8-9.1-2.4-5.9-5.6-20.4-5.7-5.5 0.5 21-24 11.9-36.8 12.7-19.6 2-39.3 4-59.1 1.8-16.1-4.3-31.7 6-47.4 0.1-13.9 5.4-11.1-15.4-13.1-17.5-8.2 5.7 6.1 21.5-9.6 18.3-9.8 0.5-19.8 1-29.5-0.6z" fill="url(#b)" fill-rule="evenodd"/><path d="m317.4 279.6c-0.2-91.8 0-183.5-0.9-275.3 6.7 7.2 19.5 2.7 25.4 3.5-1.5 90.3-3 180.6-4.5 270.9-6.1 3.6-14.3 7.8-20 0.9z" fill="url(#c)" fill-rule="evenodd"/><path d="m315.9 4.6c2.7 1.8 5.9 3 9.3 3.6 3.4 0.6 8.2 0.8 11.1 0.3 2.7-0.4 4.7-1.3 5.7-2.7-1.4-0.6-3.3-1.1-5.4-1.5-2.2-0.4-4.6-0.6-7.5-0.9l-3.6-2.4c-2.2-0.4-4.1-0.3-5.7 0.3-1.7 0.6-2.8 1.7-3.9 3.3z" fill="url(#c)" fill-rule="evenodd"/><path d="m11.6 283.5c2.3 0.4 4.7 0.4 7.6 0 2.9-0.4 6-1 9.5-2.2l0.3-3.8c3.4-0.3 6.5-0.4 9.9-0.3 3.2 0.2 6 0.7 9.5 0.7 3.4-0.2 8.2-0.8 11.4-1.3 3.3-0.3 5.8-0.4 8-0.3 0.3-0.5 0.3-1.8 0-3.8-0.3-2.1-1.7-5.8-1.6-8.3 0.2-2.3 0.9-4.2 2.6-5.7-0.7 2.2-1 4-1 5.4 0 1.5 0.8 1.5 1.3 3.5 0.5 2.1 0.8 5 1.3 8.9 3 0.1 6.6 0.3 10.5 0.6 3.9 0.5 7.3 1.7 13 1.6 5.6-0.2 15.3-2.1 21-2.6 5.7-0.1 9.8-0.3 12.7 0.3 3.4 1 7.5 1.4 12.7 1.6 5.2 0.3 12.5-0.3 17.8-0.6 5-0.4 7.2-0.7 13-1.3 5.8-0.4 15.8-0.9 22-0.9 6.1 0.1 9.9 1.4 14.7 1.3 4.7-0.1 9-0.8 13.4-1.9 0.3-0.9 0.6-1.8 1.3-3.2 0.6-1.1 1.8-2.1 2.2-4.4 0.3-2.3-0.6-7.8-0.3-9.5 0.3-1.6 0.6-1.7 1.6-0.3-0.6 2.9-0.5 5.3 0.3 7.6 0.8 2.3 3.1 4.3 4.1 6.1 0.9 1.9-0.3 3.3 1.6 4.5 1.9 1.2 3.9 1.7 9.6 1.9 5.5 0.3 17.4-0.4 23.9-0.6 6.3-0.2 8.5-0.2 14.2-0.6 5.6-0.4 13.2-1.7 19.4-1.9 6.1-0.1 12 0.4 17.5 1.3l-0.3 5.7c3 2.5 6.2 3.6 9.9 3.5 3.6-0.2 7.5-1.6 11.8-4.5l4.4-274.5c-0.2-0.2-1.3-0.5-3.5-1-2.2-0.5-5.4-0.9-9.5-1.6l-1.9-2.6c-3.2-0.1-5.6 0.1-7.6 0.6-2.1 0.6-3.5 1.3-4.5 2.6l0.3 8.2c-16.1-0.3-28.3-0.6-37.2-1.3-8.9-0.6-10.2-2.2-15.9-2.2-5.9 0.1-13.5 1.9-18.8 2.2-5.2 0.4-7.8-0.1-12.1 0-4.5 0.2-9.1 0.4-14.3 0.9-0.1 2.4-0.1 4.4-0.6 6.1-0.5 1.7-1 2.9-1.9 3.9 0.6-2.1 0.7-4.1 0.3-6-0.5-1.9-1.3-3.7-2.9-5.4-6-0.7-11.7-1-17.2-1.3-5.7-0.1-10.7-0-15.9 0.3 0.6 1.8 0.8 3.5 0.6 5.1-0.3 1.6-1.5 2.4-1.9 4.5-0.4 2.2-0.5 4.8-0.3 8.3-0-0.7-0.1-1.6-0.3-2.9-0.3-1.3-0.8-2.8-1-4.5-0.2-1.4 0.3-3.2-0.3-4.8-0.6-1.6-0.9-3.2-3.5-4.5-2.8-1.2-8.1-1.8-12.7-2.2-4.8-0.3-12.1-0.1-15.3 1-3.1 1.2-1.5 6-3.2 6-1.8 0.1-3.9-4.8-7.3-5.7-3.6-0.9-8.9 0.4-13.7 0.3-4.8 0.1-9.8 0.1-14.9 0-1 1.3-1.7 2.8-2.6 4.4-0.8 1.7-1.3 5.5-2.2 5.4-1.2-0-3.5-4.4-3.8-5.7-0.2-1.2 3-0.9 2.6-1.9-0.6-1-1.4-3.8-5.7-4.4-4.5-0.5-11.3-0.1-20.7 1.3-0.9 4.5-2 6.7-3.5 6.7-1.6-0-3.2-5.4-5.7-6.7-2.6-1.2-2.1-0.3-9.5-0.6-7.7-0.3-19.3-0.5-35.6-0.9-0.6-1.9-2.3-3.1-5.4-3.5-3.1-0.4-7.5 0.1-13 1.3l3.2 271.7c1.6 1 3.2 1.7 4.5 2.2 1.2 0.6 2.4 0.8 3.2 0.9 0.2 1.4 0.4 2.7 0.6 4.141zm-7.02-8c3.2-0.6 6.3-0.9 9.6-0.6 3.2 0.3 7.3 1.3 9.5 2.2 2.2 1 3.5 1.9 3.8 3.2-0.2-8.1-0.6-22.9-1.6-45.5-1.1-22.6-2.3-50.3-3.9-88.7-1.5-38.3-3.2-84.1-5.1-139.4-2.1-1.2-4.3-1.8-7-1.9-2.7-0-5.6 0.5-8.9 1.6 1.2 89.7 2.3 179.4 3.5 269.1zm14-267.6c14.7 0.7 25.4 1.1 32.6 1.3 7.1 0.2 7.3-1.1 10.2 0 2.8 1.2 5.1 6.3 7 7.3 1.8 1.2 3 0.7 4.1-0.6 1.2-1.2 1.9-3.6 2.6-7 4.5-0.4 8.4-0.6 11.8-0.6 3.5-0 6.6 0.2 8.3 0.6 1.4 0.7 1.1 2.1 0.9 2.8-0.2 0.8-1.8 0.9-1.6 1.9 0.2 1.3 1.7 3.5 2.8 4.8 1.1 1.3 2.6 3 3.8 2.6 1-0.4 1.7-3.3 2.6-5.1 0.8-1.7 1.5-3.5 2.2-5.4 6 0.3 11.2 0.4 15.6 0.3 4.4-0 7.8-0.8 10.5-0.3 2.5 0.6 3.9 2.7 5.4 3.8 1.5 1.2 3 3.1 4.1 3.2 1 0.1 1.8-1.3 2.5-2.5 0.6-1.2-1.1-3.4 1.3-4.5 2.4-1 8.9-1.3 13-1.3 4.1 0.2 8.8 1.2 11.5 2.2 2.7 1 3.5 1.6 4.5 3.8 0.8 2.4 0.2 7.7 1 10.2 0.8 2.6 1.9 4.2 3.5 5.1-0.6-3.3-0.7-6.1-0.3-8.6 0.3-2.4 1.6-4.1 2.2-6 0.6-1.9 0.9-3.9 1.3-5.7 0.6-0 3.3-0 8 0 4.7 0.1 11.3 0.2 20.1 0.3 1.4 1.7 2.4 3.6 3.2 5.7 0.7 2.2 1 4.6 1 7.3 1.3-1.2 2.4-2.6 3.2-4.5 0.8-1.8 1.3-3.8 1.6-6.3 12 0.1 21.6-0.1 29.3-0.6 7.6-0.5 10.5-2.2 16.2-2.23 5.5 0.2 8.6 1.9 17.2 2.6 8.6 0.6 19.8 0.8 34.1 0.6l1.3 259.9c-4.7-1-10.2-1.5-16.8-1.3-6.8 0.4-16.7 1.9-22.9 2.6-6.1 0.6-7.1 0.6-13.3 0.6-6.4 0.3-19.1 0.4-24.2 0-5.1-0.5-4.9-1.5-6-2.6-1.3-0.8-0.4-1-1.3-2.9-1-1.8-3.3-5.2-4.1-8-0.8-2.6 0.1-6.3-0.6-8-0.9-1.5-3.5-2.3-4.1-1.3-0.8 1.1 0.2 5 0 7.6-0.2 2.7-0.5 6.2-1.3 8.3-0.9 2.2-2 3.6-3.5 4.5-4.8 1-8.9 1.4-12.4 1.6-3.6 0.1-3.5-0.7-8.9-1-5.5-0.1-15.8-0-23.5 0.3-7.9 0.5-17.5 2.3-23.2 2.6-5.7 0.4-6.7-0.1-11.2-0.6-4.7-0.6-11.1-1.8-16.5-2.2-5.7-0.2-11.2 0.5-16.6 1-5.4 0.7-11.4 2.4-15.3 2.6-3.8 0.1-4.2-1.3-7.3-1.9-3.1-0.5-6.9-0.9-11.4-1.3-1.7-3.5-2.6-6.6-2.9-9.9-0.3-3.2 0.1-6.2 1.3-9.2-3 3.2-5 5.7-6 7.6-1.2 1.9-0.9 2.3-0.6 4.1 0.3 2 0.9 4.5 2.2 7.6-0.9 0.6-3.5 0.9-7.6 1.3-4.3 0.4-12.3 0.7-17.2 0.6-4.9 0-8.7-0.2-11.8-0.6l-11.2-267.2zm-5.7 273.9-1.3-4.1-4.5-1.3c3.4-0.1 6.5-0.1 9.5 0.6 3 0.7 5.7 1.7 8.3 3.2-2.7 1.1-4.9 1.6-7 1.9s-3.7 0.2-5.1-0.3zm328-276.2c-1.8 0.9-3.9 1.5-6.7 1.6-2.9 0.2-6.6-0-9.6-0.6-3-0.6-5.4-1.3-7.6-2.6 1.2-1 2.7-1.6 4.1-1.9 1.4-0.3 3.1-0.1 4.8 0.3l3.2 2.2c3.9 0.3 7.8 0.6 11.8 0.9zm-23.9 1c0.4 26.1 0.7 61.2 1 106.9 0.2 46 0.3 100.2 0.3 165.7 0.8 2.1 2.6 3.1 5.7 2.9 3-0.2 7.3-1.4 12.7-3.8l4.1-270.1c-4.2 1-7.9 1.5-11.1 1.6-3.5 0-6.4-0.6-8.6-1.3-2.2-0.6-3.5-1.1-4.1-1.9z" fill-rule="evenodd"/>',
                        svg.text(
                            'x="10" y="295" font-family="sans-serif" font-size="10px" font-style="italic"',
                            string.concat(
                                'from: ',
                                utils.toHexString(getIdfromAddress(_message.sender))
                            )
                        ),
                        svg.text(
                            'font-family="Papyrus, fantasy" font-size="12px" fill="DarkGoldenrod"',
                            WordWrap.toElement(_message.text, bodyTextFormatting)
                        )
                    )
            )
        );
    }

    function getIdfromAddress(address user) public pure returns (uint256) {
        return uint256(uint160(user));
    }

    function getAddressfromId(uint256 id) public pure returns (address) {
        return address(uint160(id));
    }

    function readText(address user) public view returns (string memory) {
        require(balanceOf(user) != 0, "NOT MINTED");

        return messages[getIdfromAddress(user)].text;
    }

    function readSender(address user) public view returns (address) {
        require(balanceOf(user) != 0, "NOT MINTED");

        return messages[getIdfromAddress(user)].sender;
    }

    function mint(address to, string memory message) public payable {
        require(msg.value >= MESSAGE_PRICE, "INSUFFICIENT PAYMENT");
        require(utils.utfStringLength(message) <= MAX_MESSAGE, 'MSG TOO LONG');
        uint256 _id = getIdfromAddress(to);
        messages[_id].text = message;
        messages[_id].sender = msg.sender;
        _mint(to, _id);
    }

    function burn() public payable {
        require(msg.value >= MESSAGE_PRICE, "INSUFFICIENT PAYMENT");
        uint256 _id = getIdfromAddress(msg.sender);
        messages[_id].text = ' ';
        messages[_id].sender = address(0);
        _burn(_id);
    }

    function withdraw() public {
        deployer.transfer(address(this).balance);
    }



}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Forked from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @notice Non transferrable unique ERC721 linked to the address of the owner 
/// @dev    The removal of ERC721 transfer logic is in defiance of the the spec

abstract contract ERC721_address_specific {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require(_balanceOf[address(uint160(id))] != 0, "NOT_MINTED");

        return address(uint160(id));
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    // No approvals, this is non transferrable and specific to the address

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    // No transfers, this is non transferrable and specific to the address

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_balanceOf[to] == 0, "ALREADY_MINTED");

        // This can only be 1 or 0
        unchecked {
            _balanceOf[to] = 1;
        }

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {

        address owner = address(uint160(id));

        require(_balanceOf[owner] == 1, "NOT_MINTED");

        // This can only be 1 or 0
        unchecked {
            _balanceOf[owner] = 0;
        }

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {utils} from './Utils.sol';

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {

    /* GLOBAL CONSTANTS */
    string internal constant _SVG = 'xmlns="http://www.w3.org/2000/svg"';
    string internal constant _HTML = 'xmlns="http://www.w3.org/1999/xhtml"';
    string internal constant _XMLNS = 'http://www.w3.org/2000/xmlns/ ';
    string internal constant _XLINK = 'http://www.w3.org/1999/xlink ';

    
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function _svg(string memory _props, string memory _children)
        internal 
        pure
        returns (string memory)
    {
        return el('svg', string.concat(_SVG, ' ', _props), _children);
    }

    function style(string memory _title, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('style', 
            string.concat(
                '.', 
                _title, 
                ' ', 
                _props)
            );
    }

    function path(string memory _d)
        internal
        pure
        returns (string memory)
    {
        return el('path', prop('d', _d, true));
    }

    function path(string memory _d, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('path', string.concat(
                                        prop('d', _d),
                                        _props
                                        )
                );
    }

    function path(string memory _d, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el(
                'path', 
                string.concat(
                            prop('d', _d),
                            _props
                            ),
                _children
                );
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function tspan(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('tspan', _props, _children);
    }

    function tspan(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('tspan', '', _children);
    }

    function line(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory cx, string memory cy, string memory r)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                )
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                ),
                _children   
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r),
                    _props
                ),
                _children   
        );
    }

    function ellipse(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props);
    }

    function ellipse(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props, _children);
    }

    function polygon(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props);
    }

    function polygon(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props, _children);
    }

    function polyline(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props);
    }

    function polyline(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    // Opensea will not render foreignObjects as of 29 Apr 2022
    function foreignObject(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('foreignObject', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.toString(offset), '%')),
                    ' ',
                    _props
                ),
                utils.NULL
            );
    }

    /* ANIMATION */
    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function animate(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animate', _props);
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct SVG (or HTML) elements without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }

    function prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if (last) {
            return string.concat(_key, '=', '"', _val, '"');
        } else {
            return string.concat(_key, '=', '"', _val, '" ');
        }
        
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// JSON utilities for base64 encoded ERC721 JSON metadata scheme
library json {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev JSON requires that double quotes be escaped or JSONs will not build correctly
    /// string.concat also requires an escape, use \\" or the constant DOUBLE_QUOTES to represent " in JSON
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    string constant DOUBLE_QUOTES = '\\"';

    function formattedMetadata(
        string memory name,
        string memory description,
        string memory svgImg
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            encode(
                bytes(
                    string.concat(
                    '{',
                    _prop('name', name),
                    _prop('description', description),
                    _xmlImage(svgImg),
                    '}'
                    )
                )
            )
        );
    }
    
    function _xmlImage(string memory _svgImg)
        internal
        pure
        returns (string memory) 
    {
        return _prop(
                        'image',
                        string.concat(
                            'data:image/svg+xml;base64,',
                            encode(bytes(_svgImg))
                        ),
                        true
        );
    }

    function _prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '"', _val, '", ');
    }

    function _prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if(last) {
            return string.concat('"', _key, '": ', '"', _val, '"');
        } else {
            return string.concat('"', _key, '": ', '"', _val, '", ');
        }
        
    }

    function _object(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '{', _val, '}');
    }
     
     /**
     * taken from Openzeppelin
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.toString(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.toString(_r),
                ',',
                utils.toString(_g),
                ',',
                utils.toString(_b),
                ',',
                formattedA,
                ')'
            );
    }

    function cssBraces(
        string memory _attribute, 
        string memory _value
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            ' {',
            _attribute,
            ': ',
            _value,
            '}'
        );
    }

    function cssBraces(
        string[] memory _attributes, 
        string[] memory _values
    )   internal
        pure
        returns (string memory)
    {
        require(_attributes.length == _values.length, "Utils: Unbalanced Arrays");
        
        uint256 len = _attributes.length;

        string memory results = ' {';

        for (uint256 i = 0; i<len; i++) {
            results = string.concat(
                                    results, 
                                    _attributes[i],
                                    ': ',
                                    _values[i],
                                     '; '
                                    );
                                    
        }

        return string.concat(results, '}');
    }

    //deals with integers (i.e. no decimals)
    function points(uint256[2][] memory pointsArray) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0]), 
                                    ',', 
                                    toString(pointsArray[i][1]),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0]), 
                            ',', 
                            toString(pointsArray[len][1]),
                            '"'
                            );
    }

    // allows for a uniform precision to be applied to all points 
    function points(uint256[2][] memory pointsArray, uint256 decimalPrecision) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0], decimalPrecision), 
                                    ',', 
                                    toString(pointsArray[i][1], decimalPrecision),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0], decimalPrecision), 
                            ',', 
                            toString(pointsArray[len][1], decimalPrecision),
                            '"'
                            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

     /**
     * taken from Openzeppelin
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

        // allows the insertion of a decimal point in the returned string at precision
    function toString(uint256 value, uint256 precision) internal pure returns (string memory) {
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
        require(precision <= digits && precision > 0, "Utils: precision invalid");
        precision == digits ? digits +=2 : digits++; //adds a space for the decimal point, 2 if it is the whole uint
        
        uint256 decimalPlacement = digits - precision - 1;
        bytes memory buffer = new bytes(digits);
        
        buffer[decimalPlacement] = 0x2E; // add the decimal point, ASCII 46/hex 2E
        if (decimalPlacement == 1) {
            buffer[0] = 0x30;
        }
        
        while (value != 0) {
            digits -= 1;
            if (digits != decimalPlacement) {
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }

        return string(buffer);
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {utils} from '../src/Utils.sol';
import {svg} from './SVG.sol';
import {strings} from 'stringUtils/strings.sol';

library WordWrap {
    using strings for *;

    struct WordWrapInfo {
        uint256 line_width;
        uint256 x;
        uint256 yFirst;
        uint256 spacing;
    }


    //yields and error if the first word is more than line_width Char long.
    function toArray(string memory _raw_text, uint256 _line_width) internal pure returns (string[] memory) {

        strings.slice memory s = _raw_text.toSlice();
        strings.slice memory delim = ' '.toSlice();
        string[] memory words  = new string[](s.count(delim));
        string[] memory completedLines = new string[](10); //set to max number of lines possible

        string memory nextLine = s.split(delim).toString();
        uint256 wordLength;
        uint256 nextLineLength;
        uint256 j = 0;

        for(uint256 i = 0; i < words.length; i++) {
            words[i] = s.split(delim).toString();
        }

        for(uint256 i = 0; i < words.length; i++) {
            wordLength = utils.utfStringLength(words[i]);
            if(wordLength > _line_width) {
                completedLines[j] = nextLine;
                j++;
                completedLines[j] = words[i];
                j++;
                nextLine = '';
                nextLineLength = 0;
            } else if ((nextLineLength + wordLength) >= _line_width) {
                completedLines[j] = nextLine;
                j++;
                nextLine = words[i];
                nextLineLength = 0;
            } else {
                nextLine = string.concat(
                    nextLine,
                    ' ',
                    words[i]
                );
                nextLineLength += wordLength + 1;
                if (i == (words.length - 1)) {
                    completedLines[j] = nextLine;
                    // if we don't need the entire max array setup another and return just that.
                    string[] memory completedLinesShorter = new string[](j+1);
                    for (uint256 k = 0; k <= j; k++) {
                        completedLinesShorter[k] = completedLines[k];
                    }
                    return completedLinesShorter;
                }
            }
        }

        return completedLines;

    }
    
    function toElement(string memory raw_text, WordWrapInfo memory formatting) pure internal returns (string memory) {

        string memory el;
        string[] memory arrayText = toArray(raw_text, formatting.line_width);

        string memory xProp = svg.prop('x', utils.toString(formatting.x));

        for (uint256 i = 0; i<arrayText.length; i++) {
            el = string.concat(
                el,
                svg.tspan(
                    string.concat(
                        xProp,
                        svg.prop('y', utils.toString(formatting.yFirst + (i * formatting.spacing)), true)
                    ),
                    arrayText[i]
                )
            );
        }

        return el;

    }



    /*

    <tspan x={0} dy={index === 0 ? 0 : 14}>
    {word}
  </tspan>

  */

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}