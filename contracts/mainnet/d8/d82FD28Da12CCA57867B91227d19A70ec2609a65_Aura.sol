// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Inspired by Solmate: https://github.com/Rari-Capital/solmate
/// Developed by 0xBasset

contract Aura {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    address public impl_;
    address public ruler;
    address public yieldRater;

    uint256 public totalSupply;
    uint256 public startingTime;

    bool public paused;

    ERC721Like public ascended;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    mapping(uint256 => Claim) public claims;

    struct Claim { uint128 time; uint128 rate; }

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "AURA";
    }

    function symbol() external pure returns (string memory) {
        return "AURA";
    }
    
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    
    function initialize(address ascended_, address rater_) external { 
        require(msg.sender == ruler);

        startingTime = 1642092968;
        ascended     = ERC721Like(ascended_);
        yieldRater   = rater_;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);


        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

    }

    /*///////////////////////////////////////////////////////////////
                              CLAIM
    //////////////////////////////////////////////////////////////*/

    function claim(uint256 id_) public {
        require(!paused, "claims are paused");

        address owner = ascended.ownerOf(id_);
        require(owner != address(0), "token does not exist");

        (uint256 amount, uint256 rate) = _claimable(id_);
        
        claims[id_].time = uint128(block.timestamp);
        claims[id_].rate = uint128(rate);

        _mint(owner, amount);
    }

    function claimMany(uint256[] calldata ids_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            claim(ids_[i]);
        }
    }

    function claimable(uint256 id) public view returns (uint256 claimable_) {
        (claimable_ , ) = _claimable(id);
    }

    function _claimable(uint256 id_) internal view returns (uint256 amount, uint256 dailyRate) {
        Claim memory cl = claims[id_];

        if (cl.rate != 0) {
            dailyRate = cl.rate;
        } else {
            // dailyRate = 1 ether;
            dailyRate = IYieldRater(yieldRater).getYieldFor(id_);
        }

        uint256 diff = block.timestamp - (cl.time == 0 ? startingTime : cl.time);
        amount  = dailyRate * diff / 1 days;
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }

    function setPaused(bool paused_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        paused = paused_;
    }

    function setYieldRate(uint256 id_, uint256 rate_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        claims[id_].rate = uint128(rate_);
    }

    function setYieldRaterAddress(address ratings_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        yieldRater = ratings_;
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

interface ERC721Like {
    function ownerOf(uint256 id_) external view returns(address);
}

interface IYieldRater {
    function getYieldFor(uint256 id) external pure returns (uint256);
}