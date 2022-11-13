// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./ERC20.sol";

/**
 * @title InnoBet
 */
contract InnoBet {
    address internal owner;

    struct winnerStruct {
        address addr;
        uint256 blockNumber;
        uint256 value;
        uint256 number;
    }

    struct betInstance {
        uint256 _price;
        uint256 _maxNumbers;
        mapping(uint256 => address) _bets;
        mapping(address => uint256[]) _addressBets;
        uint256[] _betNumbers;
        address _token;
        bool _canBet;
        uint256 _percentFee;
        winnerStruct _winner;
    }


    betInstance[] internal _betInstances;

    function createInstance(
        uint256 _price,
        uint256 _max,
        address _token,
        bool _canBet,
        uint256 _percentFee
    ) public returns (uint256) {
        require(msg.sender == owner, "Just owner can create");
        require(_max > 0, "Max should higher than 0");
        require(_token != address(0), "Token cannot be empty");
        require(_percentFee <= 100, "Percent cannot be higher than 100");
        require(_price > 0, "Price cannot be 0");

        uint256 _id = _betInstances.length;
        _betInstances.push();

        betInstance storage _instance = _betInstances[_id];

        _instance._price = _price;
        _instance._maxNumbers = _max;
        _instance._token = _token;
        _instance._canBet = _canBet;
        _instance._percentFee = _percentFee;

        return _betInstances.length - 1;
    }

    constructor() payable {
        owner = msg.sender;
    }

    function getInstance(uint256 _id) public view returns (uint256, uint256, uint256, bool, address) {
         betInstance storage _instance = _betInstances[_id];
         
         return (_instance._price, _instance._maxNumbers, _instance._percentFee, _instance._canBet, _instance._token);
    } 

    function getNumOfInstances() public view returns (uint256) {
        return _betInstances.length;
    }

    function getBets(uint256 id) public view returns (uint256[] memory) {
        return _betInstances[id]._betNumbers;
    }

    function winner(uint256 id)
        public
        view
        returns (winnerStruct memory)
    {
        return _betInstances[id]._winner;
    }

    function setCanBet(uint256 id, bool canBet) public {
        require(owner == msg.sender);
        require(_betInstances[id]._token != address(0));

        _betInstances[id]._canBet = canBet;
    }

    function getCanBet(uint256 id) public view returns (bool) {
        return _betInstances[id]._canBet;
    }

    function setFee(uint256 id, uint256 _percentFee) public {
        require(msg.sender == owner, "Just owner can do it");
        require(
            _percentFee > 0 && _percentFee <= 100,
            "Max fee is 100% and min 0%"
        );
        require(
            !_betInstances[id]._canBet,
            "Is not possible to change fee if bet is enabled"
        );

        _betInstances[id]._percentFee = _percentFee;
    }

    function getFee(uint256 id) public view returns (uint256) {
        return _betInstances[id]._percentFee;
    }

    function getBetter(uint256 id, uint256 number)
        public
        view
        returns (address)
    {
        return _betInstances[id]._bets[number];
    }

    function getBetsOf(uint256 id, address addr)
        public
        view
        returns (uint256[] memory)
    {
        return _betInstances[id]._addressBets[addr];
    }

    function bet(uint256 id, uint256 number) external payable {
        address sender = msg.sender;
        address addrOwner = _betInstances[id]._bets[number];
        require(_betInstances[id]._canBet == true, "Bets are closed");
        require(addrOwner == address(0), "Number not available");
        require(
            number <= _betInstances[id]._maxNumbers,
            "You should choice a number lower than max"
        );
        require(number > 0, "You should choice a number higher than 0");
        require(
            IERC20(_betInstances[id]._token).allowance(sender, address(this)) >
                _betInstances[id]._price,
            "Insuficient allowance"
        );

        TransferHelper.safeTransferFrom(
            _betInstances[id]._token,
            sender,
            address(this),
            _betInstances[id]._price
        );

        _betInstances[id]._betNumbers.push(number);
        _betInstances[id]._bets[number] = sender;
        _betInstances[id]._addressBets[sender].push(number);
    }

    function getMax(uint256 id) public view returns (uint256) {
        return _betInstances[id]._maxNumbers;
    }

    function randMod(uint256 _modulus, uint256 _nonce)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        _nonce
                    )
                )
            ) % _modulus;
    }

    function setMax(uint256 id, uint256 _maxToSet) public {
        require(msg.sender == owner);
        _betInstances[id]._maxNumbers = _maxToSet;
    }

    function prize(uint256 id) public view returns (uint256) {
        uint256 _percentWin = 100 - _betInstances[id]._percentFee;
        uint256 _total = _betInstances[id]._price * _betInstances[id]._maxNumbers;
        uint256 _prize = (_total / 100) * _percentWin;
        return _prize;
    }

    function sort(uint256 id, uint256 _nonce)
        public
        payable
        returns (address, uint256)
    {
        require(msg.sender == owner);
        require(
            _betInstances[id]._betNumbers.length == _betInstances[id]._maxNumbers,
            "Insuficient bets"
        );

        uint256 rand = randMod(_betInstances[id]._maxNumbers - 1, _nonce) + 1;

        address _winner = _betInstances[id]._bets[rand];

        uint256 value = prize(id);
        uint256 fee = (_betInstances[id]._maxNumbers * _betInstances[id]._price) -
            value;

        TransferHelper.safeTransfer(_betInstances[id]._token, _winner, value);
        TransferHelper.safeTransfer(_betInstances[id]._token, owner, fee);

        _betInstances[id]._winner = winnerStruct(_winner, block.number, value, rand);
        return (_winner, rand);
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