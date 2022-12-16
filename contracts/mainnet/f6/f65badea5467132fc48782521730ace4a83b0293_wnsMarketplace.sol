/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity 0.8.7;

interface WnsAddressesInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsErc721Interface {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsRegistrarInterface {
    function recoverSigner(bytes32 message, bytes memory sig) external view returns (address);
}


pragma solidity 0.8.7;

interface Erc20Interface {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsMarketplace {
 
    address private WnsAddresses;
    WnsAddressesInterface wnsAddresses;

    constructor(address addresses_) {
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == wnsAddresses.owner(), "Not authorized.");
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(addresses_);
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

    mapping(bytes => bool) invalidSignatures;

    function wnsMatch(Order[] memory order) public payable{
        require(isActive, "Contract must be active.");
        require(msg.value >= calculateCost(order) , "Value sent is not correct");

        for(uint256 i=0; i<order.length; i++) {
            wnsTransfer(order[i]);
            settlePayment(order[i].from, order[i].to, order[i].paymentToken, order[i].cost, order[i].royalty);
        }
    }

    function wnsTransfer(Order memory order) internal {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(order.contractAddress);
        require(wnsErc721.ownerOf(order.tokenId) == order.from, "Token not owned by signer");
        require(checkSignatureValidity(order.orderSig) == false, "Invalid order");

        address orderSigAddress = verifyOrderSignature(order);
        if(orderSigAddress == order.to) {
            require(msg.sender == order.from, "Not authorized by Owner");
        } else {
            require(orderSigAddress == order.from, "Not authorized by Owner");
        }
        require(verifyWnsSignature(order) == wnsAddresses.getWnsAddress("_wnsMarketplaceSigner"), "Not authorized by Wns");
        require(order.orderExpiration >= (block.timestamp*1000), "Expired credentials.");
        require(order.wnsExpiration >= (block.timestamp*1000), "Expired credentials.");

        wnsErc721.safeTransferFrom(order.from, order.to, order.tokenId);
        invalidSignatures[order.orderSig] = true;
    }

    function calculateCost(Order[] memory order) internal pure returns(uint256) {
        uint256 totalCost;
        for(uint256 i=0; i<order.length; i++) {
            if(order[i].paymentToken == address(0)) {
                totalCost = totalCost + order[i].cost;
            }
        }
        return totalCost;
    }

    function settlePayment(address from, address to, address paymentToken, uint256 amount, uint256 royalty) internal {
        if(paymentToken == address(0)) {
            payable(from).transfer(amount - royalty);
        } else {
            Erc20Interface erc20Contract = Erc20Interface(paymentToken);
            erc20Contract.transferFrom(to, from, amount - royalty);
            erc20Contract.transferFrom(to, address(this), royalty);
        }
    }

    function verifyOrderSignature(Order memory order) internal view returns(address) {
        bytes32 message = keccak256(abi.encode(order.orderAddress, order.contractAddress, order.tokenId, order.cost, order.orderExpiration));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsAddresses.getWnsAddress("_wnsRegistrar"));
        return wnsRegistrar.recoverSigner(hash, order.orderSig);
   }

   function verifyWnsSignature(Order memory order) internal view returns(address) {
        bytes32 message = keccak256(abi.encode(order.from, order.to, order.orderAddress, order.contractAddress, order.tokenId, order.cost, order.royalty, order.paymentToken, order.orderExpiration, order.wnsExpiration, order.orderSig));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsAddresses.getWnsAddress("_wnsRegistrar"));
        return wnsRegistrar.recoverSigner(message, order.wnsSig);
   }

   function checkSignatureValidity(bytes memory _signature) public view returns (bool) {
       return invalidSignatures[_signature];
   }

   function cancelOrder(bytes[] memory _signatures) public {
       for(uint256 i; i<_signatures.length; i++) {
            invalidSignatures[_signatures[i]] = true;
       }
   }

   function withdraw(address to, uint256 amount, address paymentToken) public {
        require(msg.sender == wnsAddresses.owner());
        if(paymentToken == address(0)) {
            require(amount <= address(this).balance);
            payable(to).transfer(amount);
        } else {
            Erc20Interface erc20Contract = Erc20Interface(paymentToken);
            erc20Contract.transferFrom(address(this), to, amount);
        }
    }

   function flipActiveState() public {
        require(msg.sender == wnsAddresses.owner());
        isActive = !isActive;
    }
}