// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/ITicketFactory.sol";
import "./interfaces/ITicket.sol";
import "./proxy/TicketProxy.sol";

contract TicketFactory is ITicketFactory {
    address public override beacon;
    mapping(address => bool) public override ticketRegistry;

    event TicketCreated(address ticketAddress, address ticketCreator);

    constructor(address _beacon) {
        require(_beacon != address(0), "TicketFactory: ZERO_BEACON_ADDRESS");
        beacon = _beacon;
    }

    /**
     * @notice invoked when a new ticket is created.
     */
    function createTicket(
        uint256 startBlock,
        uint256 endBlock,
        uint256 ticketPrice,
        string memory name,
        string memory symbol,
        string memory uri,
        bytes32 _salt
    ) external override {
        bytes32 salt = keccak256(abi.encode(msg.sender, _salt));
        address addr = _create(salt);

        _validateParams(startBlock, endBlock, ticketPrice);

        _initTicket(
            addr,
            startBlock,
            endBlock,
            ticketPrice,
            msg.sender,
            name,
            symbol,
            uri
        );
        ticketRegistry[addr] = true;

        emit TicketCreated(addr, msg.sender);
    }

    function _validateParams(
        uint256 startBlock,
        uint256 endBlock,
        uint256 ticketPrice
    ) internal view {
        require(startBlock > block.number, "TicketFactory: INVAID_START_BLOCK");
        require(endBlock > block.number, "TicketFactory: INVAID_END_BLOCK");
        require(ticketPrice > 0, "TicketFactory: INVAID_TICKET_PRICE");
    }

    function _create(bytes32 _salt) internal returns (address) {
        address addr;
        bytes memory beaconProxyByteCode = abi.encodePacked(
            type(TicketProxy).creationCode,
            abi.encode(beacon)
        );

        assembly {
            addr := create2(
                callvalue(),
                add(beaconProxyByteCode, 0x20),
                mload(beaconProxyByteCode),
                _salt
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function _initTicket(
        address _ticket,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _ticketPrice,
        address _newOwner,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) internal {
        ITicket ticket = ITicket(_ticket);
        ticket.initialize(
            _startBlock,
            _endBlock,
            _ticketPrice,
            _newOwner,
            _name,
            _symbol,
            _uri
        );
    }

    function preComputeAddress(address _creator, bytes32 _salt)
        public
        view
        override
        returns (address predicted)
    {
        bytes32 salt = keccak256(abi.encode(_creator, _salt));

        bytes memory beaconProxyByteCode = abi.encodePacked(
            type(TicketProxy).creationCode,
            abi.encode(beacon)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(beaconProxyByteCode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITicketFactory {
    function beacon() external view returns (address);

    function ticketRegistry(address ticket) external view returns (bool);

    function createTicket(
        uint256 startBlock,
        uint256 endBlock,
        uint256 ticketPrice,
        string memory name,
        string memory symbol,
        string memory uri,
        bytes32 _salt
    ) external;

    function preComputeAddress(address _creator, bytes32 _salt)
        external
        view
        returns (address predicted);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITicket {
    function purchaseStartBlock() external view returns (uint256);

    function purchaseEndBlock() external view returns (uint256);

    function ticketPrice() external view returns (uint256);

    function latestLotteryId() external view returns (uint256);

    function prizePool() external view returns (uint256);

    function surpriseWinnerId() external view returns (uint256);

    function lotteryWinnerId() external view returns (uint256);

    function lotteryHolders(uint256 lotteryId) external view returns (address);

    function initialize(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _ticketPrice,
        address _newOwner,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external;

    function setBaseURI(string memory _uri) external;

    function buyTicket() external payable;

    function declareSurpriseWinner() external;

    function declareLotteryWinner() external;

    function getSurpriseWinner() external view returns (address winner);

    function getLotteryWinner() external view returns (address winner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

contract TicketProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        require(_beacon != address(0), "TicketProxy: ZERO_ADDRESS");
        beacon = _beacon;
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}