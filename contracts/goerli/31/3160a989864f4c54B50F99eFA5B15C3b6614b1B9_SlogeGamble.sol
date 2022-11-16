// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
     function balanceOf(address account) external view returns (uint256);
}

contract SlogeGamble {

    address sloge;
    uint singleAmount = 100_000 ether;
    uint public changeToWin = 50;
    uint public awardMulit = 50;

    address public owner;
    address public rewardAddress;
    uint public rewardBalance;

    event GamblePlay(address, bool, uint);

    constructor(address _sloge) {
        sloge = _sloge;
        owner = msg.sender;
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }


    function play(uint amountMulit) external {

        require(msg.sender == tx.origin, "not user");

        uint reward = singleAmount * amountMulit * awardMulit / 100 ;
        require(reward <= IERC20(sloge).balanceOf(address(this)), "gamble balance insufficient");

        (bool userWin, uint randomNum) = _getRamdomeForWin();
        if (userWin) {
            safeTransfer(sloge, msg.sender, reward);
        } else {
            safeTransferFrom(sloge, msg.sender, address(this), singleAmount * amountMulit);
            rewardBalance +=  singleAmount * amountMulit* awardMulit / 100;
        }

        emit GamblePlay(msg.sender, userWin, randomNum);
    }

    function _getRamdomeForWin() private view returns (bool,uint) {
        uint random = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.basefee))) % 100) + 1;
        return (random < changeToWin, random);
    }

    function shareReward() external{
        require(msg.sender == owner, "not owner");
        require(rewardAddress != address(0), "0 address");
        safeTransfer(sloge, rewardAddress, rewardBalance);
    }

    function setVariable(uint _ctw, uint _am, address _ra) external{
        require(msg.sender == owner, "not owner");
        changeToWin = _ctw;
        awardMulit = _am;
        rewardAddress = _ra;
    }
}