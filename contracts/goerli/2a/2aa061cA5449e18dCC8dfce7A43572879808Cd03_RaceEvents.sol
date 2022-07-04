// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

interface IRace {
    function create(
        string memory _raceName,
        string memory _base_metatadata_uri,
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts,
        address[] memory _participants,
        uint _startTime
    ) external;

    function addParticipants(address[] memory _participants) external;

    function addNewRewards(
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts
    ) external;

    function publishReward(
        uint _rewardId,
        address[] memory _winners,
        uint[] memory amounts
    ) external;

    function uri(uint256 _rewardId) external view returns (string memory);

    function setURI(string memory newuri) external;

    function mint(
        address account,
        uint _rewardId,
        uint256 amount
    ) external returns (uint);

    function mintBatch(
        address to,
        uint256[] memory _rewardIds,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function getRewardDetails(uint _rewardId)
        external
        view
        returns (
            address _contract,
            string memory _name,
            string memory _metatadata_uri,
            uint _totalSupply,
            uint _availableSupply,
            address[] memory _winners,
            uint[] memory
        );
}

contract RaceEvents is Ownable {
    address[] public races;
    address deployedRaceAddress;
    event RaceCreated(address owner, address tokenContract);
    event RewardMinted(address owner, address tokenContract, uint amount);

    constructor(address _deployedRaceAddress) {
        deployedRaceAddress = _deployedRaceAddress;
        transferOwnership(tx.origin);
    }

    function deployRace(
        string memory _raceName,
        string memory _metatadata_uri,
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts,
        address[] memory _participants,
        uint _startTime
    ) public onlyOwner returns (address) {
        address newRaceAddress = Clones.cloneDeterministic(
            deployedRaceAddress,
            bytes32(races.length)
        );
        IRace(deployedRaceAddress).create(
            _raceName,
            _metatadata_uri,
            _rewardNames,
            _rewardURIs,
            _rewardAmounts,
            _participants,
            _startTime
        );
        require(address(0) != newRaceAddress, "Race creation failed");
        races.push(newRaceAddress);
        emit RaceCreated(msg.sender, races[races.length - 1]);
        return newRaceAddress;
    }

    function publishReward(
        uint256 _raceId,
        uint _rewardId,
        address[] memory _winners,
        uint[] memory _amounts
    ) public onlyOwner {
        return
            IRace(races[_raceId]).publishReward(_rewardId, _winners, _amounts);
    }

    function addParticipants(uint256 _raceId, address[] memory _participants)
        public
        onlyOwner
    {
        return IRace(races[_raceId]).addParticipants(_participants);
    }

    function addNewRewards(
        uint256 _raceId,
        string[] memory _rewardNames,
        string[] memory _rewardURIs,
        uint[] memory _rewardAmounts
    ) public onlyOwner {
        return
            IRace(races[_raceId]).addNewRewards(
                _rewardNames,
                _rewardURIs,
                _rewardAmounts
            );
    }

    function getRewardByIdAndRaceId(uint _raceId, uint _rewardId)
        public
        view
        returns (
            address _contract,
            string memory _name,
            string memory _metatadata_uri,
            uint _totalSupply,
            uint _availableSupply,
            address[] memory _winners,
            uint[] memory _amounts
        )
    {
        return IRace(races[_raceId]).getRewardDetails(_rewardId);
    }
}