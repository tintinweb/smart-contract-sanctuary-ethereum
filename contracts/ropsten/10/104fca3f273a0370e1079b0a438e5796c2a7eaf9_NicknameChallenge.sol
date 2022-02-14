/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity ^0.4.21;

// Relevant part of the CaptureTheEther contract.
contract CaptureTheEther {
    mapping (address => bytes32) public nicknameOf;

    function setNickname(bytes32 nickname) public {
        nicknameOf[msg.sender] = nickname;
    }
}

// Challenge contract. You don't need to do anything with this; it just verifies
// that you set a nickname for yourself.
contract NicknameChallenge {
    CaptureTheEther cte = CaptureTheEther(msg.sender);
    address player;

    // Your address gets passed in as a constructor parameter.
    function NicknameChallenge(address _player) public {
        player = _player;
    }

    // Check that the first character is not null.
    function isComplete() public view returns (bool) {
        return cte.nicknameOf(player)[0] != 0;
    }
}