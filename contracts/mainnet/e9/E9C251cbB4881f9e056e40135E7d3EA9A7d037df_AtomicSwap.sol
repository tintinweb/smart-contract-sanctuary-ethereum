/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
}

contract AtomicSwap {
    using SafeMath for uint;

    enum State { Empty, Initiated, Redeemed, Refunded }

    struct Swap {
        bytes32 hashedSecret;
        bytes32 secret;
        address payable initiator;
        address payable participant;
        uint refundTimestamp;
        uint value;
        uint payoff;
        State state;
    }

    event Initiated(
        bytes32 indexed _hashedSecret,
        address indexed _participant,
        address _initiator,
        uint _refundTimestamp,
        uint _value,
        uint _payoff
    );
    
    event Added(
        bytes32 indexed _hashedSecret,
        address _sender,
        uint _value
    );
    
    event Redeemed(
        bytes32 indexed _hashedSecret,
        bytes32 _secret
    );
    
    event Refunded(
        bytes32 indexed _hashedSecret
    );
    
    mapping(bytes32 => Swap) public swaps;

    modifier isRefundable(bytes32 _hashedSecret) {
        require(block.timestamp >= swaps[_hashedSecret].refundTimestamp);
        _;
    }
    
    modifier isRedeemable(bytes32 _hashedSecret, bytes32 _secret) {
        require(block.timestamp < swaps[_hashedSecret].refundTimestamp);
        require(sha256(abi.encodePacked(sha256(abi.encodePacked(_secret)))) == _hashedSecret);
        _;
    }
    
    modifier isInitiated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].state == State.Initiated);
        _;
    }
    
    modifier isInitiatable(bytes32 _hashedSecret, uint _refundTimestamp) {
        require(swaps[_hashedSecret].state == State.Empty);
        require(_refundTimestamp > block.timestamp);
        _;
    }

    modifier isAddable(bytes32 _hashedSecret) {
        require(block.timestamp <= swaps[_hashedSecret].refundTimestamp);
        _;
    }

    function add (bytes32 _hashedSecret)
        public payable isInitiated(_hashedSecret) isAddable(_hashedSecret)    
    {
        swaps[_hashedSecret].value = swaps[_hashedSecret].value.add(msg.value);

        emit Added(
            _hashedSecret,
            msg.sender,
            swaps[_hashedSecret].value
        );
    }

    function initiate (bytes32 _hashedSecret, address payable _participant, uint _refundTimestamp, uint _payoff)
        public payable isInitiatable(_hashedSecret, _refundTimestamp)    
    {
        swaps[_hashedSecret].value = msg.value.sub(_payoff);
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].initiator = msg.sender;
        swaps[_hashedSecret].participant = _participant;
        swaps[_hashedSecret].refundTimestamp = _refundTimestamp;
        swaps[_hashedSecret].payoff = _payoff;
        swaps[_hashedSecret].state = State.Initiated;

        emit Initiated(
            _hashedSecret,
            swaps[_hashedSecret].participant,
            msg.sender,
            swaps[_hashedSecret].refundTimestamp,
            swaps[_hashedSecret].value,
            swaps[_hashedSecret].payoff
        );
    }

    function refund(bytes32 _hashedSecret)
        public isInitiated(_hashedSecret) isRefundable(_hashedSecret) 
    {
        swaps[_hashedSecret].state = State.Refunded;

        emit Refunded(
            _hashedSecret
        );

        swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value.add(swaps[_hashedSecret].payoff));
        
        delete swaps[_hashedSecret];
    }

    function redeem(bytes32 _hashedSecret, bytes32 _secret) 
        public isInitiated(_hashedSecret) isRedeemable(_hashedSecret, _secret)
    {
        swaps[_hashedSecret].secret = _secret;
        swaps[_hashedSecret].state = State.Redeemed;
        
        emit Redeemed(
            _hashedSecret,
            _secret
        );

        swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
        if (swaps[_hashedSecret].payoff > 0) {
            msg.sender.transfer(swaps[_hashedSecret].payoff);
        }
        
        delete swaps[_hashedSecret];
    }
}