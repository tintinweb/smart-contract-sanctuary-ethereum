// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//   
//    ______     __   __     ______     __  __     ______     __     __   __    
//   /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   
//   \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  
//    \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
//     \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/ 
//                                                                              
//    __    __     ______     __   __     __  __     ______     __  __          
//   /\ "-./  \   /\  __ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \_\ \         
//   \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \____ \        
//    \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \/\_____\       
//     \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_____/       
//                                                                              
//   
// 
// OnChainMonkey (OCM) Genesis was the first 100% On-Chain PFP collection in 1 transaction 
// (contract: 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)
// 
// created by Metagood
//
// OCMEarth is a charity NFT
//

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract OCMEarth is ERC1155, Ownable, ReentrancyGuard {
    address public OnChainMonkeyContract = 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A;
    bool public isActive = true;
    uint256 public price = 0.1 ether;
    uint256 public minted = 1;
    uint256 public supply = 1001;

    string public uri0 = "https://arweave.net/7wZ26Lua4QUqAhBB6pYcaaDrp5BaFGII4T6Sxcp15-E";
    string public uri1 = uri0;

    constructor() ERC1155(uri0)
    {
        _mint(0x164E0D92eED7C397C675FEDE671b49cE2B289d1F, 0, 1, "");
    }

    function mint(uint256 _amount)
        public
        payable
        nonReentrant
    {   
        require(isActive, "Minting is over");
        require(_amount > 0 && _amount <= 10, "Amount must be > 0 and <= 10");
        require(msg.sender == tx.origin, "You cannot mint from a smart contract");
        require(msg.value >= price * _amount, "Not enough ETH");
        require(_amount + minted <= supply, "Not enough supply");
        minted += _amount;
        _mint(msg.sender, 1, _amount, "");
    }

    // closed forever
    function closeMint() external onlyOwner {
        isActive = false;
    }

    // Withdraw
    function withdraw(address payable withdrawAddress)
        external
        payable
        nonReentrant
        onlyOwner
    {
        require(withdrawAddress != address(0), "Withdraw address cannot be zero");
        require(address(this).balance >= 0, "Not enough eth");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    // can update 1/1 high resolution uri if the buyer wants it updated
    function setURI(string memory newuri) public onlyOwner {
        uri0 = newuri;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId>=0 && typeId<2, "type err");
        string memory num;
        string memory _uri;
        if (typeId == 0) {
            _uri = uri0;
            num = ' 1 of 1","attributes":[{"trait_type": "Resolution", "value": "14880 pixels';
        } else {
            _uri = uri1;
            num = '","attributes":[{"trait_type": "Resolution", "value": "1600 pixels';
        }
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "OCM Earth', num, '"}],"image": "', _uri,'"}'))));
    }
}