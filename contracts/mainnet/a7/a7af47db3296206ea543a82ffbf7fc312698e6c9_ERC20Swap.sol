/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: BlueOak-1.0.0
// pragma should be as specific as possible to allow easier validation.
pragma solidity = 0.8.15;

// ETHSwap creates a contract to be deployed on an ethereum network. In
// order to save on gas fees, a separate ERC20Swap contract is deployed
// for each ERC20 token. After deployed, it keeps a map of swaps that
// facilitates atomic swapping of ERC20 tokens with other crypto currencies
// that support time locks. 
//
// It accomplishes this by holding tokens acquired during a swap initiation
// until conditions are met. Prior to initiating a swap, the initiator must
// approve the ERC20Swap contract to be able to spend the initiator's tokens.
// When calling initiate, the necessary tokens for swaps are transferred to
// the swap contract. At this point the funds belong to the contract, and
// cannot be accessed by anyone else, not even the contract's deployer. The
// initiator sets a secret hash, a blocktime the funds will be accessible should
// they not be redeemed, and a participant who can redeem before or after the
// locktime. The participant can redeem at any time after the initiation
// transaction is mined if they have the secret that hashes to the secret hash.
// Otherwise, the initiator can refund funds any time after the locktime.
//
// This contract has no limits on gas used for any transactions.
//
// This contract cannot be used by other contracts or by a third party mediating
// the swap or multisig wallets.
contract ERC20Swap {
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    
    address public immutable token_address;

    // State is a type that hold's a contract's state. Empty is the uninitiated
    // or null value.
    enum State { Empty, Filled, Redeemed, Refunded }

    // Swap holds information related to one side of a single swap. The order of
    // the struct fields is important to efficiently pack the struct into as few
    // 256-bit slots as possible to reduce gas cost. In particular, the 160-bit
    // address can pack with the 8-bit State.
    struct Swap {
        bytes32 secret;
        uint256 value;
        uint initBlockNumber;
        uint refundBlockTimestamp;
        address initiator;
        address participant;
        State state;
    }

    // swaps is a map of swap secret hashes to swaps. It can be read by anyone
    // for free.
    mapping(bytes32 => Swap) public swaps;

    constructor(address token) {
        token_address = token;
    }

    // senderIsOrigin ensures that this contract cannot be used by other
    // contracts, which reduces possible attack vectors.
    modifier senderIsOrigin() {
        require(tx.origin == msg.sender, "sender != origin");
        _;
    }

    // swap returns a single swap from the swaps map.
    function swap(bytes32 secretHash)
        public view returns(Swap memory)
    {
        return swaps[secretHash];
    }

    // Initiation is used to specify the information needed to initiate a swap.
    struct Initiation {
        uint refundTimestamp;
        bytes32 secretHash;
        address participant;
        uint value;
    }

    // initiate initiates an array of swaps. It checks that all of the swaps
    // have a non zero redemptionTimestamp and value, and that none of the
    // secret hashes have ever been used previously. Once initiated, each
    // swap's state is set to Filled. The tokens equal to the sum of each
    // swap's value are now in the custody of the contract and can only be
    // retrieved through redeem or refund.
    function initiate(Initiation[] calldata initiations)
        public
        senderIsOrigin()
    {
        uint initVal = 0;
        for (uint i = 0; i < initiations.length; i++) {
            Initiation calldata initiation = initiations[i];
            Swap storage swapToUpdate = swaps[initiation.secretHash];

            require(initiation.value > 0, "0 val");
            require(initiation.refundTimestamp > 0, "0 refundTimestamp");
            require(swapToUpdate.state == State.Empty, "dup secret hash");

            swapToUpdate.initBlockNumber = block.number;
            swapToUpdate.refundBlockTimestamp = initiation.refundTimestamp;
            swapToUpdate.initiator = msg.sender;
            swapToUpdate.participant = initiation.participant;
            swapToUpdate.value = initiation.value;
            swapToUpdate.state = State.Filled;

            initVal += initiation.value;
        }

        bool success;
        bytes memory data;
        (success, data) = token_address.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, msg.sender, address(this), initVal));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer from failed');
    }

    // Redemption is used to specify the information needed to redeem a swap.
    struct Redemption {
        bytes32 secret;
        bytes32 secretHash;
    }

    // isRedeemable returns whether or not a swap identified by secretHash
    // can be redeemed using secret.
    function isRedeemable(bytes32 secretHash, bytes32 secret)
        public
        view
        returns (bool)
    {
        Swap storage swapToRedeem = swaps[secretHash];
        return swapToRedeem.state == State.Filled &&
               swapToRedeem.participant == msg.sender &&
               sha256(abi.encodePacked(secret)) == secretHash;
    }

    // redeem redeems an array of swaps contract. It checks that the sender is
    // not a contract, and that the secret hash hashes to secretHash. The ERC20
    // tokens are transferred from the contract to the sender.
    function redeem(Redemption[] calldata redemptions)
        public
        senderIsOrigin()
    {
        uint amountToRedeem = 0;
        for (uint i = 0; i < redemptions.length; i++) {
            Redemption calldata redemption = redemptions[i];
            Swap storage swapToRedeem = swaps[redemption.secretHash];

            require(swapToRedeem.state == State.Filled, "bad state");
            require(swapToRedeem.participant == msg.sender, "bad participant");
            require(sha256(abi.encodePacked(redemption.secret)) == redemption.secretHash,
                "bad secret");

            swapToRedeem.state = State.Redeemed;
            swapToRedeem.secret = redemption.secret;
            amountToRedeem += swapToRedeem.value;
        }

        bool success;
        bytes memory data;
        (success, data) = token_address.call(abi.encodeWithSelector(TRANSFER_SELECTOR, msg.sender, amountToRedeem));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }


    // isRefundable checks that a swap can be refunded. The requirements are
    // the initiator is msg.sender, the state is Filled, and the block
    // timestamp be after the swap's stored refundBlockTimestamp.
    function isRefundable(bytes32 secretHash) public view returns (bool) {
        Swap storage swapToCheck = swaps[secretHash];
        return swapToCheck.state == State.Filled &&
               swapToCheck.initiator == msg.sender &&
               block.timestamp >= swapToCheck.refundBlockTimestamp;
    }

    // refund refunds a contract. It checks that the sender is not a contract,
    // and that the refund time has passed. An amount of ERC20 tokens equal to
    // swap.value is transferred from the contract to the sender.
    function refund(bytes32 secretHash)
        public
        senderIsOrigin()
    {
        require(isRefundable(secretHash), "not refundable");
        Swap storage swapToRefund = swaps[secretHash];
        swapToRefund.state = State.Refunded;

        bool success;
        bytes memory data;
        (success, data) = token_address.call(abi.encodeWithSelector(TRANSFER_SELECTOR, msg.sender, swapToRefund.value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }
}