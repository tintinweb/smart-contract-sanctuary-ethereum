/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
    Rarity.Garden Opensea Sweeper 1.01

    Input data packing not as efficient but overall gas consumption comparable to gem.xyz (June, 2022).

    Created in the hope to be useful.
*/

contract OpenseaSweeper
{
    event Sale(address buyer, bool protected, uint256 refund);
    event Refund(address indexed sender, address indexed receiver, uint256 amount);
    event RefundAdded(address indexed receiver, uint256 amount);
    event EthRecovered(uint256 amount);

    struct Params{

        uint8 ss;
        uint256 value;
        uint256 msgValue;
        uint256 refund;
        uint256 gas_use;
        address wyvernAddress;
        address sender;
        bytes32[2][] rssMetadata;
        uint8[8] feeMethodsSidesKindsHowToCalls;
        address[14] addrs;
        uint256[18] uints;
        bytes collection;
        bytes msgSender;
        bytes calldataBuy;
        bytes calldataSell;
        bytes token_id;
    }

    mapping( address => uint256 ) public refunds;
    address public owner;

    constructor()
    {
        owner = msg.sender;
    }

    /**
        address: collection address
        uint256: fee (e.g. "250")
        uint8[]: sss ("ss" field as of OS order)
        address[]: takers (corresponding seller)
        integers[5][]: base_price, listing_time, salt, expiration_time, token_id
        bytes32[2][]: rssMetadata (first 2 as of OS order),
        bool : protected (if enabled, it will drop the entire order)
    */
    function atomicMatches(
        address collection,
        uint256 fee,
        uint8[] calldata sss,
        address[] calldata takers,
        uint256[5][] calldata integers,
        bytes32[2][] calldata rssMetadata,
        bool protected
    )
    external payable
    {
        require(integers.length == takers.length && integers.length == sss.length && integers.length == rssMetadata.length, "array lengths must be equal");

        Params memory params = Params({
            wyvernAddress : 0x7f268357A8c2552623316e2562D90e642bB538E5,
            collection : abi.encode(collection),
            sender : msg.sender,
            msgValue : msg.value,
            rssMetadata : rssMetadata,
            addrs : [address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0),address(0)],
            uints : [uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0)],
            feeMethodsSidesKindsHowToCalls : [1,0,0,1,1,1,0,1],
            calldataBuy : hex'',
            calldataSell : hex'',
            token_id : hex'',
            msgSender : hex'',
            ss : 0,
            value : 0,
            refund : 0,
            gas_use: 0
        });

        for(uint256 i = 0; i < integers.length; i++)
        {

            params.value += integers[i][0];
        }

        require(params.msgValue == params.value, "Please send the exact value");

        params.msgSender = abi.encode(params.sender);

        if(!protected)
        {
            params.gas_use = ( ( ( ( gasleft() * 10**18 ) / 100 ) * 9000 ) / integers.length ) / 10**20;
        }

        for(uint256 i = 0; i < integers.length; i++)
        {
            params.addrs = [

                params.wyvernAddress, // exchange
                address(this), // maker
                takers[i], // taker
                address(0), // feeRecipient
                0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7, // target
                address(0), // static target
                address(0), // payment token
                params.wyvernAddress, // exchange
                takers[i], // maker (=taker)
                address(0), // taker
                0x5b3256965e7C3cF26E11FCAf296DfC8807C01073, // feeRecipient
                0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7, // target
                address(0), // static target
                address(0) // payment token
            ];

            params.uints = [

                fee, // maker relayer fee
                0, // taker relayer fee
                0, // maker protocol fee
                0, // taker protocol fee
                integers[i][0], // base_price
                0, // extra
                integers[i][1], // listing_time
                0,
                integers[i][2], // salt
                fee, // maker relayer fee,
                0, // taler relayer fee
                0, // maker protocol fee
                0, // taker protocl fee
                integers[i][0], // base_price
                0, // extra
                integers[i][1], // listing_time
                integers[i][3], // expiration_time
                integers[i][2] // salt
            ];

            params.token_id = abi.encode(integers[i][4]);

            params.calldataSell =
                bytes.concat(
                    hex'fb16a595',
                    abi.encode(takers[i]),
                    hex'0000000000000000000000000000000000000000000000000000000000000000',
                    params.collection,
                    params.token_id,
                    hex'000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000'
                );

            params.calldataBuy =
                bytes.concat(
                    hex'fb16a595',
                    hex'0000000000000000000000000000000000000000000000000000000000000000',
                    params.msgSender,
                    params.collection,
                    params.token_id,
                    hex'000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000'
                );

            params.ss = sss[i];

            if(!protected)
            {
                try WyvernExchange(params.wyvernAddress).atomicMatch_{value: integers[i][0], gas: params.gas_use}
                    (
                        params.addrs,
                        params.uints,
                        params.feeMethodsSidesKindsHowToCalls,
                        params.calldataBuy,
                        params.calldataSell,
                        hex'00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                        hex'000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                        hex'',
                        hex'',
                        [params.ss, params.ss],
                        [params.rssMetadata[i][0], params.rssMetadata[i][1], params.rssMetadata[i][0], params.rssMetadata[i][1], hex'']
                    )
                {
                    // nothing, we are fine
                }
                catch Error(string memory reason)
                {
                    params.refund += integers[i][0];
                }
                catch
                {
                    params.refund += integers[i][0];
                }
            }
            else
            {
                WyvernExchange(params.wyvernAddress).atomicMatch_{value: integers[i][0]}
                (
                    params.addrs,
                    params.uints,
                    params.feeMethodsSidesKindsHowToCalls,
                    params.calldataBuy,
                    params.calldataSell,
                    hex'00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                    hex'000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                    hex'',
                    hex'',
                    [params.ss, params.ss],
                    [params.rssMetadata[i][0], params.rssMetadata[i][1], params.rssMetadata[i][0], params.rssMetadata[i][1], hex'']
                );
            }
        }

        emit Sale(params.sender, protected, params.refund);

        if(params.refund != 0)
        {
            require(params.msgValue != params.refund, "Couldn't sweep anything");

            (bool success,) = payable(params.sender).call{value: params.refund}("");

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

    function transferOwnership(address newOwner) external
    {
        require(msg.sender == owner, "Not the owner");

        owner = newOwner;
    }
}

interface WyvernExchange
{

    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    )
    external
    payable;
}