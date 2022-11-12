// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./ERC20.sol";

/**
 * @title InnoBet
 */
contract InnotBet {
    uint256[] internal betNumbers;
    mapping(uint256 => address) internal bets;
    mapping(address => uint256[]) internal addressBets;
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

    function getBets() public view returns(uint256[] memory){
        return betNumbers;
    }

    function numWinners() public view returns(uint256) {
        return winners.length;
    }

    function winner(uint256 n) public view returns(winnerStruct memory) {
        return winners[n];
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

    function getBetsOf(address addr) public view returns (uint256[] memory) {
        return addressBets[addr];
    }

    function bet(uint256 number) external payable {
        address sender = msg.sender;
        address addrOwner = bets[number];
        require(_canBet == true, "Bets are closed");
        require(addrOwner == address(0), "Number not available");
        require(number <= max, "You should choice a number lower than max");
        require(number > 0, "You should choice a number higher than 0");
        require(IERC20(_token).allowance(sender, address(this)) > _price, "Insuficient allowance");

        TransferHelper.safeTransferFrom(
            _token,
            sender,
            address(this),
            _price
        );

        betNumbers.push(number);
        bets[number] = sender;
        addressBets[sender].push(number);
    }

    function getMax() public view returns (uint256) {
        return max;
    }

    function randMod(uint256 _modulus, uint256 _nonce) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nonce)
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

    function sort(uint256 _nonce) public payable returns (address, uint256) {
        require(msg.sender == owner);
        require(betNumbers.length == max, "Insuficient bets");

        uint256 rand = randMod(max - 1, _nonce) + 1;

        address _winner = bets[rand];

        uint256 value = prize();
        uint256 fee = (max*_price)-prize();
        
        TransferHelper.safeTransfer(_token, _winner, value);
        TransferHelper.safeTransfer(_token, owner, fee);

        winners.push(winnerStruct(_winner, block.number, value));

        for (uint256 i = 0; i < max; i++) {
            uint256[] memory nothing;
            address better = bets[i];
            addressBets[better] = nothing;
            bets[i] = address(0);
        }
        uint256[] memory newBets;
        betNumbers = newBets;

        return (_winner, rand);
    }

    function lastWinner() public view returns (address, uint256, uint256) {
        winnerStruct memory _winner = winners[winners.length - 1];
        return (_winner.addr, _winner.blockNumber, _winner.value);
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