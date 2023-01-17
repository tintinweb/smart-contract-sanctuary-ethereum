// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ChallengeDetail.sol";

contract CreateChallenges{
    using SafeMath for uint256;

    event createNewChallenge(address indexed _creator);

    /**
     * @dev Value send to contract should be equal with `amount`.
     */
    modifier validateFee(uint256 _amount) {
        require(msg.value == _amount, "Invalid network fee");
        _;
    }

    /**
     * @dev Create new Challenge with token.
     * @param _stakeHolders : 0-sponsor, 1-challenger, 2-fee address, 3-token address
     * @param _primaryRequired : 0-duration, 1-start, 2-end, 3-goal, 4-day require
     * @param _awardReceivers : list receivers address
     * @param _index : index slpit receiver array
     * @param _allowGiveUp : challenge allow give up or not
     * @param _gasData : 0-token for sever success, 1-token for sever fail, 2-coin for challenger transaction fee
     * @param _allAwardToSponsorWhenGiveUp : transfer all award back to sponsor or not
     */
    function CreateChallenge(
        address payable[] memory _stakeHolders,
        address[] memory _erc20ListAddress,
        address[] memory _erc721Address,
        uint256[] memory _primaryRequired,
        address payable[] memory _awardReceivers,
        uint256 _index,
        bool[] memory _allowGiveUp,
        uint256[] memory _gasData,
        bool _allAwardToSponsorWhenGiveUp,
        uint256[] memory _awardReceiversPercent,
        uint256 _totalAmount
    )
    public
    payable
    validateFee(_gasData[2])
    returns (address challengeAddress)
    {
        ChallengeDetail newChallengeDetails = (new ChallengeDetail){value: msg.value}(
            _stakeHolders,
            _erc20ListAddress[0],
            _erc721Address,
            _primaryRequired,
            _awardReceivers,
            _index,
            _allowGiveUp,
            _gasData,
            _allAwardToSponsorWhenGiveUp,   
            _awardReceiversPercent,
            _totalAmount
        );      
        emit createNewChallenge(address(newChallengeDetails));
        return address(newChallengeDetails);
    }
}