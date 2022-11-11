// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./ERC20.sol";

/**
 * @title InnoBet
 */
contract InnotBet {
    uint256 internal nBets = 0;
    mapping(uint256 => address) internal bets;
    mapping(address => uint256[]) internal addressBets;
    uint256 internal randNonce = 0;
    uint256 internal max = 100;
    address internal owner;
    winnerStruct[] internal winners;

    uint256 internal _percentFee = 10;
    uint256 internal _price = 10000;
    address internal _token;
    bool internal _canBet = false;

    struct winnerStruct {
        address addr;
        uint256 blockNumber;
        uint256 value;
    }

    constructor() payable {
        owner = msg.sender;
    }

    function setCanBet(bool canBet) public {
        require(owner == msg.sender);
        require(_token != address(0));

        _canBet = canBet;
    }

    function getCanBet() public view returns (bool) {
        return _canBet;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) public {
        require(msg.sender == owner);

        _price = price;
    }

    function getToken() public view returns (address) {
        return _token;
    }

    function setToken(address token) public {
        require(msg.sender == owner);

        _token = token;
    }

    function setFee(uint256 percent) public {
        require(msg.sender == owner);
        require(_percentFee > 0 && _percentFee <= 100);

        _percentFee = percent;
    }

    function getFee() public view returns (uint256) {
        return _percentFee;
    }

    function getBetter(uint256 number) public view returns (address) {
        return bets[number];
    }

    function getBets(address addr) public view returns (uint256[] memory) {
        return addressBets[addr];
    }

    function bet(uint256 number) external payable {
        require(_canBet == true, "Bets are closed");
        require(bets[number] == address(0), "Number not available");
        require(number <= max, "You should choice a number lower than max");
        require(number > 0, "You should choice a number higher than 0");

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            _price
        );

        nBets++;
        bets[number] = msg.sender;
        addressBets[msg.sender].push(number);
    }

    function getMax() public view returns (uint256) {
        return max;
    }

    function randMod(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }

    function setMax(uint256 maxToSet) public {
        require(msg.sender == owner);
        max = maxToSet;
    }

    function prize() public view returns (uint256) {
        uint256 _percentWin = 100 - _percentFee;
        uint256 _total = _price * max;
        uint256 _prize = (_total / 100) * _percentWin;
        return _prize;
    }

    function sort() public payable returns (address, uint256) {
        require(msg.sender == owner);
        require(nBets == max, "Insuficient bets");

        uint256 rand = randMod(max - 1) + 1;

        address winner = bets[rand];

        uint256 value = prize();
        TransferHelper.safeTransfer(_token, winner, value);
        winners.push(winnerStruct(winner, block.number, value));

        for (uint256 i = 0; i < max; i++) {
            uint256[] memory nothing;
            address better = bets[i];
            addressBets[better] = nothing;
            bets[i] = address(0);
        }
        nBets = 0;

        return (winner, rand);
    }

    function lastWinner() public view returns (address, uint256) {
        winnerStruct memory winner = winners[winners.length - 1];
        return (winner.addr, winner.blockNumber);
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}