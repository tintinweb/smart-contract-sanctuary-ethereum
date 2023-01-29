// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMain {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }
    function fee() external returns(uint);
    function claimRank(uint256 term) external payable;
    function claimMintReward() external payable;
    function userMints(address user) external view returns(MintInfo memory);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function getMintReward(uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eeaRate) external view returns(uint);
}

contract Minter {
    address public owner;
    IMain main;
    uint public term;
    constructor(address user, address _main){
        owner = user;
        main = IMain(_main);
    }
    function claimRank(uint256 _term) external {
        term = _term;
        main.claimRank(term);
    }
    function claimMintReward() external payable {
        uint fee = main.fee();
        main.claimMintReward{value : fee}();
        main.transfer(owner, main.balanceOf(address(this)));
    }
    function getUserMintInfo() public view returns(IMain.MintInfo memory){
        return main.userMints(address(this));
    }
    function getMintReward() external view returns(uint){
        IMain.MintInfo memory r = getUserMintInfo();
        return main.getMintReward(r.rank, r.term, r.maturityTs, r.amplifier, r.eaaRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Minter.sol";
//import "hardhat/console.sol";

contract MinterFactory
{
    address public main;
    mapping(address => address[]) minters;
    constructor(address _main){
        main = _main;
    }
    function minterFactory(uint amount, uint term) external {
        for (uint i = 0; i < amount; ++i) {
            Minter minter = new Minter(msg.sender, main);
            minters[msg.sender].push(address(minter));
            minter.claimRank(term);
        }
    }

    function getUserMinters(address user) public view returns (address[] memory){
        return minters[user];
    }

    function getUserMinterInfo(address user) public view returns (IMain.MintInfo[] memory){
        uint t = minters[user].length;
        IMain.MintInfo[] memory minterInfo = new IMain.MintInfo[](t);
        for( uint i = 0 ; i < t ; ++ i ){
            Minter minter = Minter(minters[user][i]);
            minterInfo[i] = minter.getUserMintInfo();
        }
        return minterInfo;
    }

    function claimRank(uint limit) external{
        uint t = minters[msg.sender].length;
        uint j;
        for( uint i = t ; i > 0 ; -- i ){
            if( j == limit ) break;
            Minter minter = Minter(minters[msg.sender][i-1]);
            IMain.MintInfo memory info = minter.getUserMintInfo();
            if( info.maturityTs > 0 ){
                continue;
            }
            minter.claimRank( minter.term() );
            ++j;
        }
    }
    function claimMintReward(uint limit) external payable{
        uint fee = IMain(main).fee();
        uint t = minters[msg.sender].length;
        uint j;
        for( uint i = t ; i > 0 ; -- i ){
            if( j == limit ) break;
            Minter minter = Minter(minters[msg.sender][i-1]);
            IMain.MintInfo memory info = minter.getUserMintInfo();
            if( block.timestamp > info.maturityTs && info.rank > 0 ){
                minter.claimMintReward{value : fee}();
                ++j;
            }
        }
    }
    function getMintReward(address user) public view returns (uint[] memory){
        uint t = minters[user].length;
        uint[] memory reward = new uint[](t);
        for( uint i = 0 ; i < t ; ++ i ){
            Minter minter = Minter(minters[user][i]);
            reward[i] = minter.getMintReward();
        }
        return reward;
    }
}