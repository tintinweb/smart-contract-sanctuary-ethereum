/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.5.0;

// From file: openzeppelin-contracts/contracts/math/SafeMath.sol 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

// From file: openzeppelin-contracts/contracts/utils/Address.sol 
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol 
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

contract AtomicSwap is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    enum State { Empty, Initiated, Redeemed, Refunded }

    struct Swap {
        bytes32 hashedSecret;
        bytes32 secret;
        address contractAddr;
        address participant;
        address payable initiator;
        uint refundTimestamp;
        uint countdown;
        uint value;
        uint payoff;
        bool active;
        State state;
    }
    
    event Initiated(
        bytes32 indexed _hashedSecret,
        address indexed _contract,
        address indexed _participant,
        address _initiator,
        uint _refundTimestamp,
        uint _countdown,
        uint _value,
        uint _payoff,
        bool _active
    );
    event Added(
        bytes32 indexed _hashedSecret,
        address _sender,
        uint _value  
    );
    event Activated(
        bytes32 indexed _hashedSecret
    );
    event Redeemed(
        bytes32 indexed _hashedSecret,
        bytes32 _secret
    );
    event Refunded(
        bytes32 indexed _hashedSecret
    );

    mapping(bytes32 => Swap) public swaps;

    modifier onlyByInitiator(bytes32 _hashedSecret) {
        require(msg.sender == swaps[_hashedSecret].initiator, "sender is not the initiator");
        _;
    }

    modifier isInitiatable(bytes32 _hashedSecret, address _participant, uint _refundTimestamp, uint _countdown) {
        require(_participant != address(0), "invalid participant address");
        require(swaps[_hashedSecret].state == State.Empty, "swap for this hash is initiated");
        require(block.timestamp <= _refundTimestamp, "invalid refundTimestamp");
        require(_countdown < _refundTimestamp, "invalid countdown");
        _;
    }
    
    modifier isInitiated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].state == State.Initiated, "swap for this hash is empty or spent");
        _;
    }

    modifier isAddable(bytes32 _hashedSecret) {
        require(block.timestamp <= swaps[_hashedSecret].refundTimestamp, "refundTimestamp has come");
        _;
    }
        
    modifier isActivated(bytes32 _hashedSecret) {
        require(swaps[_hashedSecret].active, "swap is not active");
        _;
    }    
    
    modifier isNotActivated(bytes32 _hashedSecret) {
        require(!swaps[_hashedSecret].active, "swap is active");
        _;
    }

    modifier isRedeemable(bytes32 _hashedSecret, bytes32 _secret) {
        require(block.timestamp <= swaps[_hashedSecret].refundTimestamp, "refundTimestamp has come");
        require(sha256(abi.encodePacked(sha256(abi.encodePacked(_secret)))) == _hashedSecret, "secret is not correct");
        _;
    }

    modifier isRefundable(bytes32 _hashedSecret) {
        require(block.timestamp > swaps[_hashedSecret].refundTimestamp, "refundTimestamp has not come");
        _;
    }

    function initiate (bytes32 _hashedSecret, address _contract, address _participant, uint _refundTimestamp, uint _countdown, uint _value, uint _payoff, bool _active)
        public nonReentrant isInitiatable(_hashedSecret, _participant, _refundTimestamp, _countdown)
    {
        IERC20(_contract).safeTransferFrom(msg.sender, address(this), _value);

        swaps[_hashedSecret].value = _value.sub(_payoff);
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].contractAddr = _contract;
        swaps[_hashedSecret].participant = _participant;
        swaps[_hashedSecret].initiator = msg.sender;
        swaps[_hashedSecret].refundTimestamp = _refundTimestamp;
        swaps[_hashedSecret].countdown = _countdown;
        swaps[_hashedSecret].payoff = _payoff;
        swaps[_hashedSecret].active = _active;
        swaps[_hashedSecret].state = State.Initiated;

        emit Initiated(
            _hashedSecret,
            _contract,
            _participant,
            msg.sender,
            _refundTimestamp,
            _countdown,
            _value.sub(_payoff),
            _payoff,
            _active
        );
    }
    
    function add (bytes32 _hashedSecret, uint _value)
        public nonReentrant isInitiated(_hashedSecret) isAddable(_hashedSecret)    
    {
        IERC20(swaps[_hashedSecret].contractAddr).safeTransferFrom(msg.sender, address(this), _value);
        
        swaps[_hashedSecret].value = swaps[_hashedSecret].value.add(_value);

        emit Added(
            _hashedSecret,
            msg.sender,
            swaps[_hashedSecret].value
        );
    }
    
    function activate (bytes32 _hashedSecret)
        public nonReentrant isInitiated(_hashedSecret) isNotActivated(_hashedSecret) onlyByInitiator(_hashedSecret)
    {
        swaps[_hashedSecret].active = true;

        emit Activated(
            _hashedSecret
        );
    }

    function redeem(bytes32 _hashedSecret, bytes32 _secret) 
        public nonReentrant isInitiated(_hashedSecret) isActivated(_hashedSecret) isRedeemable(_hashedSecret, _secret) 
    {
        swaps[_hashedSecret].secret = _secret;
        swaps[_hashedSecret].state = State.Redeemed;

        if (block.timestamp > swaps[_hashedSecret].refundTimestamp.sub(swaps[_hashedSecret].countdown)) {
            
            IERC20(swaps[_hashedSecret].contractAddr).safeTransfer(swaps[_hashedSecret].participant, swaps[_hashedSecret].value);
            
            if(swaps[_hashedSecret].payoff > 0) {
                IERC20(swaps[_hashedSecret].contractAddr).safeTransfer(msg.sender, swaps[_hashedSecret].payoff);
            }
        }
        else {
            IERC20(swaps[_hashedSecret].contractAddr).safeTransfer(swaps[_hashedSecret].participant, swaps[_hashedSecret].value.add(swaps[_hashedSecret].payoff));
        }
        
        emit Redeemed(
            _hashedSecret,
            _secret
        );
        
        delete swaps[_hashedSecret];
    }

    function refund(bytes32 _hashedSecret)
        public nonReentrant isInitiated(_hashedSecret) isRefundable(_hashedSecret) 
    {
        swaps[_hashedSecret].state = State.Refunded;

        IERC20(swaps[_hashedSecret].contractAddr).safeTransfer(swaps[_hashedSecret].initiator, swaps[_hashedSecret].value.add(swaps[_hashedSecret].payoff));

        emit Refunded(
            _hashedSecret
        );
        
        delete swaps[_hashedSecret];
    }
}