/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ERC1155
{
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

interface ERC721
{
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function balanceOf(address _owner) external view returns (uint256);
}

contract MultiSendNFTs 
{
    uint256 public batchPrice;
    uint256 public passCollectionMinAmount;
    address public owner;
    address public passCollection;
    mapping(address => uint256) public refunds;

    event TransferSuccess(address _sender, address _to);
    event TransferError(address _sender, address _to, string reason);
    event EthRecovered(uint256 amount);
    event Refund(address indexed sender, address indexed receiver, uint256 amount);
    event RefundAdded(address indexed receiver, uint256 amount);
    
    constructor()
    {
        owner = msg.sender;
        batchPrice = 50000000000000;
        passCollection = 0x4A58FbB36f5E6b48D37BB0119054E13dD1C4701B;
        passCollectionMinAmount = 20;
    }

    function transferMultiBatch721(address _collection, address[] calldata _to,  uint256[] calldata _ids) external payable
    {
        require(_to.length != 0, "transferMultiBatch721: please add at least one recipient.");
        require(_ids.length == _to.length, "transferMultiBatch721: ids and to must have the same length.");
        
        uint256 costs;
        address sender = msg.sender;
        uint256 value = msg.value;
        bool pass = hasPass(sender);

        if(!pass)
        {
            require(value == _to.length * batchPrice, "Please send the exact amount.");
        }
        else
        {
            require(value == 0, "No amount required.");
        }

        for(uint256 i = 0; i < _to.length; i++)
        {
            try ERC721(_collection).safeTransferFrom(sender, _to[i], _ids[i])
            {
                costs += batchPrice;
                emit TransferSuccess(sender, _to[i]);
            }
            catch Error(string memory reason)
            {
                emit TransferError(sender, _to[i], reason);
            }
            catch
            {
                
                emit TransferError(sender, _to[i], "Generic Error");
            }
        }

        if(!pass)
        {
            handleRefund(sender, value, costs);
        }
    }

    function transferMultiSeries721(address _collection, address[] calldata _to,  uint256 _tokenIdStart) external payable
    {
        require(_to.length != 0, "transferMultiSeries721: please add at least one recipient.");
        
        uint256 costs;
        address sender = msg.sender;
        uint256 value = msg.value;
        bool pass = hasPass(sender);

        if(!pass)
        {
            require(value == _to.length * batchPrice, "Please send the exact amount.");
        }
        else
        {
            require(value == 0, "No amount required.");
        }

        for(uint256 i = 0; i < _to.length; i++)
        {
            try ERC721(_collection).safeTransferFrom(sender, _to[i], _tokenIdStart)
            {
                _tokenIdStart++;
                costs += batchPrice;
                emit TransferSuccess(sender, _to[i]);
            }
            catch Error(string memory reason)
            {
                emit TransferError(sender, _to[i], reason);
            }
            catch
            {
                
                emit TransferError(sender, _to[i], "Generic Error");
            }
        }

        if(!pass)
        {
            handleRefund(sender, value, costs);
        }
    }

    function transferMultiBatch1155(address _collection, address[] calldata _to,  uint256[] calldata _ids, uint256[] calldata _amounts) external payable
    {
        require(_to.length != 0, "transferMultiBatch1155: please add at least one recipient.");
        require(_ids.length != 0, "transferMultiBatch1155: please add at least one NFT.");
        require(_ids.length == _amounts.length, "transferMultiBatch1155: ids and amounts differ in length.");
        
        uint256 costs;
        address sender = msg.sender;
        uint256 value = msg.value;
        bool pass = hasPass(sender);

        if(!pass)
        {
            require(value == _to.length * batchPrice, "Please send the exact amount.");
        }
        else
        {
            require(value == 0, "No amount required.");
        }

        for(uint256 i = 0; i < _to.length; i++)
        {
            try ERC1155(_collection).safeTransferFrom(sender, _to[i], _ids[i], _amounts[i], "")
            {
                costs += batchPrice;
                emit TransferSuccess(sender, _to[i]);
            }
            catch Error(string memory reason)
            {
                emit TransferError(sender, _to[i], reason);
            }
            catch
            {
                emit TransferError(sender, _to[i], "Generic Error");
            }
        }

        if(!pass)
        {
            handleRefund(sender, value, costs);
        }
    }

    function transferMultiSeries1155(address _collection, address[] calldata _to, uint256 _tokenIdStart, uint256 _amount) external payable
    {
        require(_to.length != 0, "transferMultiSeries1155: please add at least one recipient.");
        require(_amount != 0, "transferMultiSeries1155: amount must be larger than zero.");
        
        uint256 costs;
        address sender = msg.sender;
        uint256 value = msg.value;
        bool pass = hasPass(sender);

        if(!pass)
        {
            require(value == _to.length * batchPrice, "Please send the exact amount.");
        }
        else
        {
            require(value == 0, "No amount required.");
        }

        for(uint256 i = 0; i < _to.length; i++)
        {
            try ERC1155(_collection).safeTransferFrom(sender, _to[i], _tokenIdStart, _amount, "")
            {
                _tokenIdStart++;
                costs += batchPrice;
                emit TransferSuccess(sender, _to[i]);
            }
            catch Error(string memory reason)
            {
                emit TransferError(sender, _to[i], reason);
            }
            catch
            {
                emit TransferError(sender, _to[i], "Generic Error");
            }
        }

        if(!pass)
        {
            handleRefund(sender, value, costs);
        }
    }

    function handleRefund(address sender, uint256 value, uint256 costs) internal
    {

        uint256 refund = value - costs;

        if(refund == 0)
        {
            return;
        }

        (bool success,) = payable(sender).call{value: refund}("");
        
        if(!success)
        {
            refunds[sender] += refund;
            emit RefundAdded(sender, refund);
        }
    }

    function hasPass(address sender) internal view returns(bool)
    {

        if(passCollection != address(0))
        {
            return ERC721(passCollection).balanceOf(sender) >= passCollectionMinAmount;
        }

        return false;
    }

    function setBatchPrice(uint256 price) external
    {
        require(msg.sender == owner, "Not the owner");

        batchPrice = price;
    }

    function setPassCollection(address collection, uint256 min) external
    {
        require(msg.sender == owner, "Not the owner");

        passCollection = collection;
        passCollectionMinAmount = min;
    }

    function performRefundUser() external
    {
        address msgSender = msg.sender;
        uint256 tmp = refunds[msgSender];
        refunds[msgSender] = 0;

        (bool success,) = payable(msgSender).call{value: tmp}("");

        if(success)
        {
            emit Refund(msgSender, msgSender, tmp);
        }
    }

    function performRefundAdmin(address user) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        uint256 tmp = refunds[user];
        refunds[user] = 0;

        (bool success,) = payable(user).call{value: tmp}("");

        if(success)
        {
            emit Refund(msgSender, user, tmp);
        }
    }

    function performEthRecover(uint256 amount) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        (bool success,) = payable(msgSender).call{value: amount}("");

        if(success)
        {
            emit EthRecovered(amount);
        }
    }

    function performErc721Recover(address collection, uint256 token_id) external
    {
        address msgSender = msg.sender;

        require(msgSender == owner, "Not the owner");

        ERC721(collection).safeTransferFrom(address(this), msgSender, token_id);
    }

    function transferOwnership(address newOwner) external
    {
        require(msg.sender == owner, "Not the owner");

        owner = newOwner;
    }
}