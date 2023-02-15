// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface Isuretoken {
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
    function buyToken() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function burnToken(uint256 _amount) external;
    function burnTokenFor(address _owner, uint256 _amount) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import { Isuretoken } from "./interfaces/Isuretoken.sol";

contract Vcontract {
    ///owner of the contract
    address public controller;
    ///@dev token used as ticket to vote
    Isuretoken ticket;
    ///@dev name of the voting contract
    string public name;

    //@dev number of people that have voted in the ballot
    uint256 public totalVotes;

    //@dev the starting period of the vote
    uint256 public Open;

    //@dev timestamp the vote ends
    uint public close;

    //@dev the winner of the competition
    uint256 public _winner;
    
    ///@dev token per vote
    uint256 public tokenPerVote;

    uint256 private numOfVotes;

    address[] public voterAddress;

    address private ticketToken;

    struct contenderData {
        string name;
        uint8 votePoints;
    }

    mapping(string => contenderData) public contender;
    string[]  contenders;
    mapping(address => bool) private hasVoted;

    constructor (string memory _contractName, string[] memory _contenders, uint256 _period, uint256 _tokenPerVote, address voterCord) {
        name = _contractName;
        Open = block.timestamp;
        close = Open + _period;


        tokenPerVote = _tokenPerVote;
        ticketToken = voterCord;
        controller = msg.sender;

        require(_contenders.length == 3, "There can only be three contenders");

        for (uint i = 0; i < 3; i++) {
           // contender.name = _contenders[i];
            contenders.push(_contenders[i]);
        }

    }
        
    
    function vote (string[] calldata _candidateRank ) external {
        require(block.timestamp < close, "Vote has ended");
        require(Isuretoken(ticketToken).balanceOf(msg.sender) > tokenPerVote, "Not enough ticket token to vote");

        require(hasVoted[msg.sender] == false, "Cannot vote twice");
        require(_candidateRank.length == 3, "You can only rank three contenders");

        contender[_candidateRank[0]].votePoints += 3;
        contender[_candidateRank[1]].votePoints += 2;
        contender[_candidateRank[2]].votePoints += 1;

        hasVoted[msg.sender] == true;
        numOfVotes += 1;

        voterAddress.push(msg.sender);

        uint256 controllerIncentive = (tokenPerVote * 10) / 100;
        uint256 burnAmount = tokenPerVote - controllerIncentive;

        Isuretoken(ticketToken).transferFrom(msg.sender, controller, controllerIncentive);
        Isuretoken(ticketToken).burnTokenFor(msg.sender, burnAmount);

    }



    function winner () external view returns (string memory){
            string memory win = contender[contenders[0]].votePoints >
                contender[contenders[1]].votePoints
                ? // if true
                (
                    contender[contenders[0]].votePoints >
                        contender[contenders[2]].votePoints
                        ? contender[contenders[0]].name
                        : contender[contenders[2]].name
                )
                : // if false
                (
                    contender[contenders[1]].votePoints >
                        contender[contenders[2]].votePoints
                        ? contender[contenders[1]].name
                        : contender[contenders[2]].name
                );

            return win;
    }

    function returnVoters() external view returns(address[] memory){
        return voterAddress;
    }

    function name_() external view returns(string memory) {
        return name;
    }


       
}