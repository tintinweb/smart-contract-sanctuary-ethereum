/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// File: contracts/MultiSender.sol

pragma solidity ^0.7.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

abstract contract BEP20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view virtual returns (uint256);

    function transfer(address to, uint256 value) public virtual;

    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract BEP20 is BEP20Basic {
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual;

    function approve(address spender, uint256 value) public virtual;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//   Payzus Multi Sender, support BSC and BEP20 Tokens

contract BasicToken is BEP20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public override {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }
}

//   Payzus Multi Sender, support BSC and BEP20 Tokens

contract StandardToken is BasicToken, BEP20 {
    mapping(address => mapping(address => uint256)) allowed;
    using SafeMath for uint256;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public override {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

//   Payzus Multi Sender, support BSC and BEP20 Tokens

contract Ownable {
    address payable public owner;

    constructor() {
        owner = 0xEdd96191dD8Fa97bFeD27E605857eB0589923Bd3;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract MultiSender is Ownable, StandardToken {
    using SafeMath for uint256;

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address private receiverAddress;
    uint256 public txFee = 0;
    uint256 public VIPFee = 0;
    address _tokenAddress;
    StandardToken token = StandardToken(_tokenAddress);

    /* VIP List */
    mapping(address => bool) private vipList;

    /*
     *  Register VIP
     */
    function registerVIP() public payable {
        require(msg.value >= VIPFee);
        require(owner.send(msg.value));
        vipList[msg.sender] = true;
    }

    /*
     *  VIP list
     */
    function addToVIPList(address[] memory _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = true;
        }
    }

    /*
     * Remove address from VIP List by Owner
     */
    function removeFromVIPList(address[] memory _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = false;
        }
    }

    /*
     * Check isVIP
     */
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner || vipList[_addr];
    }

    /*
     * set vip fee
     */
    function setVIPFee(uint256 _fee) public onlyOwner {
        VIPFee = _fee;
    }

    /*
     * set tx fee
     */
    function setTxFee(uint256 _fee) public onlyOwner {
        txFee = _fee;
    }

    function BSCSendSameValue(address payable[] memory _to, uint256 _value)
        internal
    {
        uint256 sendAmount = _to.length.mul(_value);
        uint256 transferValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (vip) {
            require(transferValue >= sendAmount);
        } else {
            require(transferValue >= sendAmount.add(txFee));
        }
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            transferValue = transferValue.sub(_value);
            require(_to[i].send(_value));
        }

        if (!vip) {
            owner.transfer(txFee);
        }

        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function BSCSendDifferentValue(
        address payable[] memory _to,
        uint256[] memory _value
    ) internal {
        uint256 sendAmount = 0;

        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount += _value[i];
        }
        uint256 remainingValue = msg.value;

        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount.add(txFee));
        }

        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            require(_to[i].send(_value[i]));
        }

        if (!vip) {
            owner.transfer(txFee);
        }
        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function coinSendSameValue(
        address _tokenAddress,
        address[] memory _to,
        uint256 _value
    ) internal {
        uint256 sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }
        require(_to.length <= 255);

        address from = msg.sender;
        uint256 sendAmount = _to.length.mul(_value);

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }
        if (!vip) {
            owner.transfer(txFee);
        }
        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    function coinSendDifferentValue(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) internal {
        uint256 sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }

        require(_to.length == _value.length);
        require(_to.length <= 255);

        uint256 sendAmount = 0;

        for (uint8 i = 0; i < _to.length; i++) {
            sendAmount += _value[i];
        }

        StandardToken token = StandardToken(_tokenAddress);

        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
        }

        if (!vip) {
            owner.transfer(txFee);
        }
        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    /*
        Send BSC with the same value by a explicit call mBSC
    */

    function sendBSC(address payable[] memory _to, uint256 _value)
        public
        payable
    {
        BSCSendSameValue(_to, _value);
    }

    /*
        Send BSC with the different value by a implicit call BSC
    */

    function mutiSendBSCWithDifferentValue(
        address payable[] memory _to,
        uint256[] memory _value
    ) public payable {
        BSCSendDifferentValue(_to, _value);
    }

    /*
        Send BSCer with the same value by a implicit call BSC
    */

    function mutiSendBSCWithSameValue(
        address payable[] memory _to,
        uint256 _value
    ) public payable {
        BSCSendSameValue(_to, _value);
    }

    /*
        Send coin with the same value by a implicit call BSC
    */

    function mutiSendCoinWithSameValue(
        address _tokenAddress,
        address[] memory _to,
        uint256 _value
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a implicit call BSC, this BSC can save some fee.
    */
    function mutiSendCoinWithDifferentValue(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a explicit call BSC
    */
    function multisendToken(
        address _tokenAddress,
        address[] memory _to,
        uint256[] memory _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }
    /*
        Send coin with the same value by a explicit call BSC
    */
}