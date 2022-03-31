/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsErc721Interface {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);

}

pragma solidity 0.8.7;

interface WnsStructs {
    struct Register {
        string name;
        string extension;
        address registrant;
        uint256 cost;
        uint256 expiration;
        address[] splitAddresses;
        uint256[] splitAmounts;
    }

    struct RegisterStruct {
        Register[] register;
        bytes[] signature;
        uint256 registrationCost;
    }
}

pragma solidity 0.8.7;

interface WnsRegistrarInterface is WnsStructs {
    function recoverSigner(bytes32 message, bytes memory sig) external view returns (address);
    function wnsRegister(Register[] memory register, bytes[] memory sig) external payable;
}

pragma solidity 0.8.7;

interface Erc20Interface {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsMarketplace is WnsStructs {
 
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

    struct Order {
        address from;
        address to;
        address orderAddress;
        address contractAddress;
        uint256 tokenId;
        uint256 cost;
        uint256 royalty;
        address paymentToken;
        uint256 orderExpiration;
        uint256 wnsExpiration;
        bytes orderSig;
        bytes wnsSig;
    }

    bool public isActive = true;

    function wnsMatch(Order[] memory order, uint256 totalCost, RegisterStruct memory registerStruct) public payable{
        require(isActive, "Contract must be active.");
        if(registerStruct.signature.length != 0) {
            require(registerStruct.register.length == registerStruct.signature.length, "Invalid parameters.");
            WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
            wnsRegistrar.wnsRegister{value:registerStruct.registrationCost}(registerStruct.register, registerStruct.signature);
        }

        require(msg.value <= totalCost , "Value sent is not correct");
        for(uint256 i=0; i<order.length; i++) {
            wnsTransfer(order[i]);
            settlePayment(order[i].from, order[i].to, order[i].paymentToken, order[i].cost - order[i].royalty);
        }
    }

    function wnsTransfer(Order memory order) internal {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(order.contractAddress);
        require(wnsErc721.ownerOf(order.tokenId) == order.from, "Token not owned by signer");
        address orderSigAddress = verifyOrderSignature(order);
        if(orderSigAddress == order.to) {
            require(msg.sender == order.from, "Not authorized by Owner");
        } else {
            require(orderSigAddress == order.from, "Not authorized by Owner");
        }
        require(verifyWnsSignature(order) == wnsRegistry.getWnsAddress("_wnsMarketplaceSigner"), "Not authorized by Wns");
        require(order.orderExpiration >= block.timestamp, "Expired credentials.");
        require(order.wnsExpiration >= block.timestamp, "Expired credentials.");

        wnsErc721.safeTransferFrom(order.from, order.to, order.tokenId);
    }

    function settlePayment(address from, address to, address paymentToken, uint256 amount) internal {
        if(paymentToken == address(0)) {
            payable(from).transfer(amount);
        } else {
            Erc20Interface erc20Contract = Erc20Interface(paymentToken);
            erc20Contract.transferFrom(to, from, amount);
        }
    }

    function verifyOrderSignature(Order memory order) internal view returns(address) {
        bytes32 message = keccak256(abi.encode(order.orderAddress, order.contractAddress, order.tokenId, order.cost, order.orderExpiration));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        return wnsRegistrar.recoverSigner(hash, order.orderSig);
   }

   function verifyWnsSignature(Order memory order) internal view returns(address) {
        bytes32 message = keccak256(abi.encode(order.from, order.to, order.orderAddress, order.contractAddress, order.tokenId, order.cost, order.royalty, order.paymentToken, order.orderExpiration, order.wnsExpiration, order.orderSig));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        return wnsRegistrar.recoverSigner(message, order.wnsSig);
   }

   function flipActiveState() public {
        require(msg.sender == wnsRegistry.owner());
        isActive = !isActive;
    }
}