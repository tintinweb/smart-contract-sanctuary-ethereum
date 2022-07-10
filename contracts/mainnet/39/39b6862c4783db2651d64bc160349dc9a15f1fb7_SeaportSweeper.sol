/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
    Rarity.Garden Seaport Sweeper 1.0.4

    Created in the hope to be useful.

    The sweeper's MatchOrders() function operates on one collection at a time to save gas.
    Your Web3 app shouldn't try to pass token ids from distinct collections.
*/

interface IERC721{

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface Seaport
{
    enum BasicOrderType {
        ETH_TO_ERC721_FULL_OPEN,
        ETH_TO_ERC721_PARTIAL_OPEN,
        ETH_TO_ERC721_FULL_RESTRICTED,
        ETH_TO_ERC721_PARTIAL_RESTRICTED
    }

    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    struct BasicOrderParameters {
        address considerationToken;
        uint256 considerationIdentifier;
        uint256 considerationAmount;
        address payable offerer;
        address zone;
        address offerToken;
        uint256 offerIdentifier;
        uint256 offerAmount;
        BasicOrderType basicOrderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 offererConduitKey;
        bytes32 fulfillerConduitKey;
        uint256 totalOriginalAdditionalRecipients;
        AdditionalRecipient[] additionalRecipients;
        bytes signature;
    }

    function fulfillBasicOrder(BasicOrderParameters calldata parameters) external payable returns (bool fulfilled);
}

contract SeaportSweeper
{
    event Sale(address buyer, bool protected, uint256 refund);
    event Refund(address indexed sender, address indexed receiver, uint256 amount);
    event RefundAdded(address indexed receiver, uint256 amount);
    event EthRecovered(uint256 amount);

    struct Params{
        uint256 value;
        uint256 msgValue;
        uint256 refund;
        uint256 gas_use;
        address seaportAddress;
        address zone;
        address sender;
        address emptyAddress;
        address collection;
        bytes32 conduitKey;
        bytes32 emptyBytes32;
        uint256[] values;
    }

    struct MiniOrderParameters {
        address payable offerer;
        uint256 salt;
        uint256 offerIdentifier;
        uint256 considerationAmount;
        uint256 startTime;
        uint256 endTime;
        Seaport.BasicOrderType orderType;
        bytes32 zoneHash;
        Seaport.AdditionalRecipient[] additionalRecipients;
        bytes signature;
    }

    mapping( address => uint256 ) public refunds;
    address public owner;

    constructor()
    {
        owner = msg.sender;
    }

    function MatchOrders(
        address collection,
        MiniOrderParameters[] calldata miniOrder,
        bool protected
    )
    external payable
    {
        require(miniOrder.length != 0, "MiniOrderParameters size must be larger than zero");

        Params memory params = Params({
            seaportAddress : 0x00000000006c3852cbEf3e08E8dF289169EdE581,
            zone : 0x004C00500000aD104D7DBd00e3ae0A5C00560C00,
            conduitKey : 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
            emptyBytes32 : 0x0000000000000000000000000000000000000000000000000000000000000000,
            emptyAddress : 0x0000000000000000000000000000000000000000,
            sender : msg.sender,
            msgValue : msg.value,
            collection : collection,
            value : 0,
            refund : 0,
            gas_use: 0,
            values : new uint256[](miniOrder.length)
        });

        for(uint256 i = 0; i < miniOrder.length; i++)
        {
            params.values[i] += miniOrder[i].considerationAmount;

            for(uint256 j = 0; j < miniOrder[i].additionalRecipients.length; j++)
            {
                params.values[i] += miniOrder[i].additionalRecipients[j].amount;
            }

            params.value += params.values[i];
        }

        require(params.msgValue == params.value, "Please send the exact value");

        // in case of disabled protection, we distribute 90% of remaining gas equally to each fulfillment.
        // the remaining 10% should be enough for transfers and refund management, if any.
        if(!protected)
        {
            params.gas_use = ( ( ( ( gasleft() * 10**18 ) / 100 ) * 9000 ) / miniOrder.length ) / 10**20;
        }

        for(uint256 i = 0; i < miniOrder.length; i++)
        {
            // we assume static parameter values like zone and conduit key to save gas.
            Seaport.BasicOrderParameters memory parameters = Seaport.BasicOrderParameters({
                considerationToken : params.emptyAddress,
                considerationIdentifier : 0,
                considerationAmount : miniOrder[i].considerationAmount,
                offerer : miniOrder[i].offerer,
                zone : params.zone,
                offerToken : params.collection,
                offerIdentifier : miniOrder[i].offerIdentifier,
                offerAmount : 1,
                basicOrderType : miniOrder[i].orderType,
                startTime : miniOrder[i].startTime,
                endTime : miniOrder[i].endTime,
                zoneHash: miniOrder[i].zoneHash,
                salt : miniOrder[i].salt,
                offererConduitKey : params.conduitKey,
                fulfillerConduitKey : params.emptyBytes32,
                totalOriginalAdditionalRecipients : miniOrder[i].additionalRecipients.length,
                additionalRecipients : miniOrder[i].additionalRecipients,
                signature : miniOrder[i].signature
            });

            // protection turned off.
            if(!protected)
            {
                try Seaport(params.seaportAddress).fulfillBasicOrder{value: params.values[i], gas: params.gas_use}(parameters)
                {
                    // at this point, the transfer is excluded from protection to prevent non-refundable circumstances.
                    IERC721(params.collection).safeTransferFrom(address(this), params.sender, miniOrder[i].offerIdentifier);
                }
                catch Error(string memory reason)
                {
                    params.refund += params.values[i];
                }
                catch
                {
                    params.refund += params.values[i];
                }
            }
            // protection turned on.
            else
            {
                Seaport(params.seaportAddress).fulfillBasicOrder{value: params.values[i]}(parameters);
                IERC721(params.collection).safeTransferFrom(address(this), params.sender, miniOrder[i].offerIdentifier);
            }
        }

        emit Sale(params.sender, protected, params.refund);

        if(params.refund != 0)
        {
            // if nothing could be bought, we save a bit gas by halting the entire transaction and returning all remaining gas + eth sent.
            // in this case, separate refunds aren't necessary.
            require(params.msgValue != params.refund, "Couldn't sweep anything");

            (bool success,) = payable(params.sender).call{value: params.refund}("");

            // in case sending back eth fails for some reason, it can still be refunded later on.
            if(!success)
            {
                refunds[params.sender] += params.refund;
                emit RefundAdded(params.sender, params.refund);
            }
        }
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

        IERC721(collection).safeTransferFrom(address(this), msgSender, token_id);
    }

    function transferOwnership(address newOwner) external
    {
        require(msg.sender == owner, "Not the owner");

        owner = newOwner;
    }
}