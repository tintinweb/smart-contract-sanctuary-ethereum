/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name) external;
    function setRecord(uint256 _tokenId, string memory _name) external;
    function getRecord(bytes32 _hash) external view returns (uint256);
    
}

pragma solidity 0.8.7;

interface WnsErc721Interface {
    function mintErc721(address to) external;
    function getNextTokenId() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

}


pragma solidity 0.8.7;

contract Computation {
    function computeNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }
}

pragma solidity 0.8.7;


abstract contract Signatures {

    struct Register {
        string name;
        string extension;
        address registrant;
        uint256 cost;
        uint256 expiration;
        address[] splitAddresses;
        uint256[] splitAmounts;
    }
     
   function verifySignature(Register memory _register, bytes memory sig) internal pure returns(address) {
        bytes32 message = keccak256(abi.encode(_register.name, _register.extension, _register.registrant, _register.cost, _register.expiration, _register.splitAddresses, _register.splitAmounts));
        return recoverSigner(message, sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract WnsRegistrar is Computation, Signatures {

    address private WnsRegistry;
    WnsRegistryInterface wnsRegistry;

    constructor(address registry_) {
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    bool public isActive = false;

    function wnsRegister(Register[] memory register, bytes[] memory sig) public payable {
        require(isActive, "Registration must be active.");
        require(register.length == sig.length, "Invalid parameters.");
        require(calculateCost(register) <= msg.value, "Ether value is not correct.");
        for(uint256 i=0; i<register.length; i++) {
            _register(register[i], sig[i]);
        }
    }

    function _register(Register memory register, bytes memory sig) internal {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        require(verifySignature(register,sig) == wnsRegistry.getWnsAddress("_wnsSigner"), "Not authorized.");
        require(register.expiration >= block.timestamp, "Expired credentials.");
        bytes32 _hash = computeNamehash(register.name);
        require(wnsRegistry.getRecord(_hash) == 0, "Name already exists.");
        
        wnsErc721.mintErc721(register.registrant);
        wnsRegistry.setRecord(_hash, wnsErc721.getNextTokenId(), string(abi.encodePacked(register.name, register.extension)));
        settleSplits(register.splitAddresses, register.splitAmounts);
    }

    function migrateExtension(string memory _name, string memory _extension, bytes memory sig) public {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        bytes32 message = keccak256(abi.encode(_name, _extension));
        require(recoverSigner(message, sig) == wnsRegistry.getWnsAddress("_wnsSigner"), "Not authorized.");
        uint256 _tokenId = wnsRegistry.getRecord(computeNamehash(_name)) - 1;
        require(wnsErc721.ownerOf(_tokenId) == msg.sender, "Not owned by caller");
        wnsRegistry.setRecord(_tokenId + 1, string(abi.encodePacked(_name, _extension)));
    }

    function calculateCost(Register[] memory register) internal pure returns (uint256) {
        uint256 cost;
        for(uint256 i=0; i<register.length; i++) {
            cost = cost + register[i].cost;
        }
        return cost;
    }

    function settleSplits(address[] memory splitAddresses, uint256[] memory splitAmounts) internal {
        uint256 addLength = splitAddresses.length;
        uint256 amountLength = splitAmounts.length;
        require(addLength == amountLength, "Invalid parameters.");
        if(addLength > 0) {
            for(uint256 i=0; i<addLength; i++) {
                payable(splitAddresses[i]).transfer(splitAmounts[i]);
            }
        }
    }

    function withdraw(address to, uint256 amount) public {
        require(msg.sender == wnsRegistry.owner());
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }
    
    function flipActiveState() public {
        require(msg.sender == wnsRegistry.owner());
        isActive = !isActive;
    }

}