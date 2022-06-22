/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenTimelock {

    // Mapping of ERC20s and their respective release time.
    mapping (address => uint) ReleaseTime;
    // beneficiary of released tokens
    address private immutable beneficiary;

    constructor() {
        beneficiary = msg.sender;
    }

    // Returns the release time for the corresponding token.
    function getReleaseTime(address _token) public view virtual returns (uint256) {
        return ReleaseTime[_token];
    }

    // Locks tokens on behalf of the beneficiary. A lock must be longer than a month, but shorter than a year.
    function lockToken(address _token, uint64 _releaseTime) public {
        require(msg.sender == beneficiary, "Locker must be beneficiary");
        require(_releaseTime > block.timestamp + 30 days, "Lock must be at least a month long.");
        require(_releaseTime < block.timestamp + 365 days, "Lock must be less than a year long.");
        ReleaseTime[_token] = _releaseTime;
    }

    // Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release time.
    function release(address _token) public virtual {
        require(block.timestamp >= ReleaseTime[_token], "TokenTimelock: current time is before release time");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");
        IERC20(_token).transfer(beneficiary, amount);
    }
}