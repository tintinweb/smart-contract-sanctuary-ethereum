// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721S.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";

interface IRandomNumGenerator {
    function getRandomNumber(
        uint256 _seed,
        uint256 _limit,
        uint256 _random
    ) external view returns (uint16);
}

interface IStakingDevice {
    function getMultifier(uint16 tokenId) external view returns (uint8);
}

interface IAFF {
    function mint(address to, uint256 amount) external;
}

contract GoldStaking is Ownable, IERC721Receiver {
    using Address for address;

    struct NftInfo {
        uint256 lastClaimTime;
        uint256 penddingAmount;
        uint256 value;
    }

    struct TokenReward {
        uint16 id;
        uint256 reward;
        uint8 nftType;
        uint256 tax;
    }

    struct UserRewards {
        uint256 totalReward;
        TokenReward[] tokenRewards;
    }

    address private admin;

    uint256 public stakeStopTime;

    address public angryfrogAddress;
    address public deviceAddress;
    address public affAddress;
    address public randomGen;

    uint256 public stakedFrog;
    uint256 public stakedDevice;
    uint256 public totalClaimedToken;
    uint256 public totalStealedToken;

    uint256 public dailyRewardAmount = 3 * 10**18;
    uint8 private taxFeeOfCitizen = 30;
    uint8 private taxFeeOfGangster = 10;
    uint16[] private multifierValue = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    mapping(uint16 => NftInfo) public nftInfos;
    mapping(uint16 => uint8) public nftTypes; // 0: Citizen, 1: Gangster, 2: Business
    mapping(address => uint16[]) public stakers;
    mapping(address => uint16[]) public devices;

    address[] public businessHolders;
    address[] public gangsterHolders;
    uint256 public businessReward;
    uint256 public gangsterReward;

    bool public lastClaimStealed;

    event StakeDeivce(address indexed user, uint16[] tokenIds);
    event Stake(address indexed user, uint16[] tokenIds);
    event Claim(
        address indexed user,
        uint16[] tokenIds,
        uint256 amount,
        bool unstake
    );
    event WithdrawDevice(address indexed user, uint16[] tokenId);
    event Steal(address from, address to, uint256 amount, bool unstake);

    string public constant CONTRACT_NAME = "Gold Contract";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant STAKE_TYPEHASH =
        keccak256("Stake(address user,uint16[] tokenIds,uint8[] types)");

    constructor(address _admin) {
        admin = _admin;
    }

    function setContractAddress(
        address _randomGen,
        address _angryfrogAddress,
        address _deviceAddress,
        address _affAddress
    ) public onlyOwner {
        require(
            _randomGen != address(0) &&
                _angryfrogAddress != address(0) &&
                _deviceAddress != address(0) &&
                _affAddress != address(0),
            "Zero address."
        );
        randomGen = _randomGen;
        angryfrogAddress = _angryfrogAddress;
        deviceAddress = _deviceAddress;
        affAddress = _affAddress;
    }

    function setDailyTokenReward(
        uint256 _dailyRewardAmount,
        uint8 _taxFeeOfGangster,
        uint8 _taxFeeOfCitizen
    ) public onlyOwner {
        dailyRewardAmount = _dailyRewardAmount;
        taxFeeOfGangster = _taxFeeOfGangster;
        taxFeeOfCitizen = _taxFeeOfCitizen;
    }

    function getStakedFrogCounts()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            stakedFrog,
            businessHolders.length,
            gangsterHolders.length,
            stakedFrog - businessHolders.length - gangsterHolders.length
        );
    }

    function setStakeStop(bool _stop) public onlyOwner {
        if (_stop) {
            stakeStopTime = block.timestamp;
        } else {
            stakeStopTime = 0;
        }
    }

    function setMultifiers(uint16[] memory _mutifiers) public onlyOwner {
        for (uint8 i; i < 10; i++) {
            multifierValue[i] = _mutifiers[i];
        }
    }

    function getMultifierByDeviceId(uint16 deviceId)
        public
        view
        returns (uint16)
    {
        uint8 number = IStakingDevice(deviceAddress).getMultifier(deviceId);
        return multifierValue[number];
    }

    function getDailyRewardByTokenId(uint16 tokenId)
        public
        view
        returns (uint256)
    {
        if (nftTypes[tokenId] == 2) {
            return (dailyRewardAmount * 3) / 1440;
        } else if (nftTypes[tokenId] == 1) {
            return (dailyRewardAmount * 2) / 1440;
        } else {
            return dailyRewardAmount / 1440;
        }
    }

    function getRewardByTokenId(uint16 tokenId, address user)
        public
        view
        returns (uint256)
    {
        NftInfo memory nftInfo = nftInfos[tokenId];

        if (nftInfo.lastClaimTime == 0) {
            return 0;
        } else {
            uint16[] memory deviceIds = devices[user];
            uint16 _totalMultifier = 100;
            for (uint8 i; i < deviceIds.length; i++) {
                _totalMultifier =
                    _totalMultifier +
                    getMultifierByDeviceId(deviceIds[i]);
            }

            uint256 currentTime = stakeStopTime == 0
                ? block.timestamp
                : stakeStopTime;

            return
                nftInfo.penddingAmount +
                ((getDailyRewardByTokenId(tokenId) * _totalMultifier) / 100) *
                ((currentTime - nftInfo.lastClaimTime) / 1 minutes);
        }
    }

    function getDevices(address user) public view returns (uint16[] memory) {
        uint16[] memory deviceIds = devices[user];
        return deviceIds;
    }

    function getReward(address user) public view returns (UserRewards memory) {
        uint16[] memory tokenIds = stakers[user];

        uint256 _totalReward;

        TokenReward[] memory _tokenRewards = new TokenReward[](tokenIds.length);

        for (uint8 i; i < tokenIds.length; i++) {
            uint256 _available = getRewardByTokenId(tokenIds[i], user);
            uint256 _tax;

            if (nftTypes[tokenIds[i]] == 2) {
                _tax = businessReward - nftInfos[tokenIds[i]].value;
            } else if (nftTypes[tokenIds[i]] == 1) {
                _tax = gangsterReward - nftInfos[tokenIds[i]].value;
            }

            _totalReward = _totalReward + _available + _tax;

            _tokenRewards[i] = TokenReward({
                id: tokenIds[i],
                nftType: nftTypes[tokenIds[i]],
                reward: _available,
                tax: _tax
            });
        }

        UserRewards memory _userRewards = UserRewards({
            totalReward: _totalReward,
            tokenRewards: _tokenRewards
        });

        return _userRewards;
    }

    function stake(
        uint16[] memory tokenIds,
        uint8[] memory types,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(stakeStopTime == 0, "Stake: Not started yet");
        require(tx.origin == msg.sender, "Only EOA");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                STAKE_TYPEHASH,
                msg.sender,
                keccak256(abi.encodePacked(tokenIds)),
                keccak256(abi.encodePacked(types))
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint16[] storage staker = stakers[msg.sender];

        for (uint8 i; i < tokenIds.length; i++) {
            if (msg.sender != angryfrogAddress) {
                require(
                    IERC721S(angryfrogAddress).ownerOf(tokenIds[i]) ==
                        msg.sender,
                    "This NFT does not belong to address"
                );
                IERC721S(angryfrogAddress).transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            }

            staker.push(tokenIds[i]);
            nftInfos[tokenIds[i]].lastClaimTime = block.timestamp;

            if (types[i] == 2) {
                nftTypes[tokenIds[i]] = 2;
                businessHolders.push(msg.sender);
                nftInfos[tokenIds[i]].value = businessReward;
            } else if (types[i] == 1) {
                nftTypes[tokenIds[i]] = 1;
                gangsterHolders.push(msg.sender);
                nftInfos[tokenIds[i]].value = gangsterReward;
            }
        }

        stakedFrog = stakedFrog + tokenIds.length;

        emit Stake(msg.sender, tokenIds);
    }

    function stakeDevice(address account, uint16[] memory deviceIds) public {
        require(stakeStopTime == 0, "Stake: Not starte yet");
        require(
            account == msg.sender || msg.sender == deviceAddress,
            "You do not have a permission to do that"
        );
        _tempClaimReward(account);

        uint16[] storage staker = stakers[account];
        uint16[] storage device = devices[account];
        require(
            staker.length >= device.length + deviceIds.length,
            "Stake: Device stake is limited."
        );

        for (uint8 i; i < deviceIds.length; i++) {
            if (msg.sender != deviceAddress) {
                require(
                    IERC721S(deviceAddress).ownerOf(deviceIds[i]) == msg.sender,
                    "This NFT does not belong to address"
                );
                IERC721S(deviceAddress).transferFrom(
                    msg.sender,
                    address(this),
                    deviceIds[i]
                );
            }
            device.push(deviceIds[i]);
        }

        stakedDevice = stakedDevice + deviceIds.length;
        emit StakeDeivce(account, deviceIds);
    }

    function _tempClaimReward(address account) internal {
        uint16[] memory tokenIds = stakers[account];
        for (uint8 i; i < tokenIds.length; i++) {
            uint256 available = getRewardByTokenId(tokenIds[i], account);
            if (available > 0) {
                nftInfos[tokenIds[i]].penddingAmount =
                    nftInfos[tokenIds[i]].penddingAmount +
                    available;
                nftInfos[tokenIds[i]].lastClaimTime = block.timestamp;
            }
        }
    }

    function _setNftInfo(uint16 tokenId) internal {
        nftInfos[tokenId].lastClaimTime = block.timestamp;
        nftInfos[tokenId].penddingAmount = 0;
    }

    function _resetNftInfo(uint16 tokenId) internal {
        nftInfos[tokenId].lastClaimTime = 0;
        nftInfos[tokenId].penddingAmount = 0;
    }

    function _existTokenId(address account, uint16 tokenId)
        internal
        view
        returns (bool, uint8)
    {
        uint16[] memory tokenIds = stakers[account];
        for (uint8 i; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function _existDeviceId(address account, uint16 tokenId)
        internal
        view
        returns (bool, uint8)
    {
        uint16[] memory tokenIds = devices[account];
        for (uint8 i; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function claimReward(
        uint16[] memory tokenIds,
        bool safe,
        bool unstake
    ) external {
        require(tx.origin == msg.sender, "Only EOA");

        for (uint8 i; i < tokenIds.length; i++) {
            (bool exist, ) = _existTokenId(msg.sender, tokenIds[i]);
            require(exist, "Not Your Own");
        }

        uint16[] storage staker = stakers[msg.sender];

        uint256 totalReward;
        uint256 totalBusinessReward;
        uint256 totalGangsterReward;
        uint256 totalCitizenReward;

        for (uint8 i; i < tokenIds.length; i++) {
            if (nftTypes[tokenIds[i]] == 2) {
                uint256 reward = _claimFromBusiness(tokenIds[i]);
                totalBusinessReward = totalBusinessReward + reward;

                if (unstake) {
                    uint256 indexOfHolder = 0;
                    for (uint256 j; j < businessHolders.length; j++) {
                        if (businessHolders[j] == msg.sender) {
                            indexOfHolder = j;
                            break;
                        }
                    }
                    businessHolders[indexOfHolder] = businessHolders[
                        businessHolders.length - 1
                    ];
                    businessHolders.pop();
                }
            } else if (nftTypes[tokenIds[i]] == 1) {
                uint256 reward = _claimFromGangster(tokenIds[i], safe);
                totalGangsterReward = totalGangsterReward + reward;

                if (unstake) {
                    uint256 indexOfHolder = 0;
                    for (uint256 j; j < gangsterHolders.length; j++) {
                        if (gangsterHolders[j] == msg.sender) {
                            indexOfHolder = j;
                            break;
                        }
                    }
                    gangsterHolders[indexOfHolder] = gangsterHolders[
                        gangsterHolders.length - 1
                    ];
                    gangsterHolders.pop();
                }
            } else {
                uint256 reward = _claimFromCitizen(tokenIds[i], safe);
                totalCitizenReward = totalCitizenReward + reward;
            }

            if (unstake) {
                _resetNftInfo(tokenIds[i]);
                (, uint8 index) = _existTokenId(msg.sender, tokenIds[i]);
                staker[index] = staker[staker.length - 1];
                staker.pop();

                IERC721S(angryfrogAddress).transferFrom(
                    address(this),
                    _msgSender(),
                    tokenIds[i]
                );
            } else {
                _setNftInfo(tokenIds[i]);
            }
        }

        totalReward =
            totalBusinessReward +
            totalGangsterReward +
            totalCitizenReward;
        totalClaimedToken = totalClaimedToken + totalReward;

        if (unstake) {
            stakedFrog = stakedFrog - tokenIds.length;
        }

        if (safe) {
            IAFF(affAddress).mint(msg.sender, totalReward);
            emit Claim(_msgSender(), tokenIds, totalReward, unstake);
        } else {
            address recipient = _selectRecipientFromGangster(totalReward);

            if (recipient != msg.sender) {
                totalStealedToken =
                    totalStealedToken +
                    totalGangsterReward +
                    totalCitizenReward;

                IAFF(affAddress).mint(
                    recipient,
                    totalGangsterReward + totalCitizenReward
                );
                lastClaimStealed = true;
                emit Steal(
                    msg.sender,
                    recipient,
                    totalGangsterReward + totalCitizenReward,
                    unstake
                );

                IAFF(affAddress).mint(recipient, totalBusinessReward);
                emit Claim(
                    _msgSender(),
                    tokenIds,
                    totalBusinessReward,
                    unstake
                );
            } else {
                lastClaimStealed = false;
                IAFF(affAddress).mint(recipient, totalReward);
                emit Claim(_msgSender(), tokenIds, totalReward, unstake);
            }
        }
    }

    function _claimFromCitizen(uint16 tokenId, bool safe)
        internal
        returns (uint256)
    {
        uint256 available = getRewardByTokenId(tokenId, msg.sender);
        if (safe) {
            uint256 _tax = (available * taxFeeOfCitizen) / 100;
            _payTaxForCitizen(_tax);
            return available - _tax;
        } else {
            return available;
        }
    }

    function _claimFromGangster(uint16 tokenId, bool safe)
        internal
        returns (uint256)
    {
        uint256 available = getRewardByTokenId(tokenId, msg.sender);
        uint256 taxReward = gangsterReward - nftInfos[tokenId].value;
        nftInfos[tokenId].value = gangsterReward;

        if (safe) {
            uint256 _tax = ((available + taxReward) * taxFeeOfGangster) / 100;
            _payTaxForGangster(_tax);
            return (available + taxReward) - _tax;
        } else {
            return (available + taxReward);
        }
    }

    function _claimFromBusiness(uint16 tokenId) internal returns (uint256) {
        uint256 available = getRewardByTokenId(tokenId, msg.sender);
        uint256 taxReward = businessReward - nftInfos[tokenId].value;
        nftInfos[tokenId].value = businessReward;

        return (available + taxReward);
    }

    function withdrawDevice(uint16[] memory deviceIds) external {
        require(tx.origin == msg.sender, "Only EOA");

        for (uint8 i; i < deviceIds.length; i++) {
            (bool exist, ) = _existDeviceId(msg.sender, deviceIds[i]);
            require(exist, "Not Your Own");
        }
        _tempClaimReward(msg.sender);

        uint16[] storage device = devices[msg.sender];

        for (uint8 i; i < deviceIds.length; i++) {
            (, uint8 index) = _existDeviceId(msg.sender, deviceIds[i]);
            device[index] = device[device.length - 1];
            device.pop();

            IERC721S(deviceAddress).transferFrom(
                address(this),
                _msgSender(),
                deviceIds[i]
            );
        }

        stakedDevice = stakedDevice - deviceIds.length;
        emit WithdrawDevice(_msgSender(), deviceIds);
    }

    function _payTaxForCitizen(uint256 _amount) internal {
        uint256 _amountForGangster = _amount / 3;
        uint256 _amountForBusiness = _amount - _amountForGangster;

        if (businessHolders.length != 0) {
            businessReward += _amountForBusiness / businessHolders.length;
        }
        if (gangsterHolders.length != 0) {
            gangsterReward += _amountForGangster / gangsterHolders.length;
        }
    }

    function _payTaxForGangster(uint256 _amount) internal {
        if (businessHolders.length != 0) {
            businessReward += _amount / businessHolders.length;
        }
    }

    function _selectRecipient(uint256 seed) private view returns (address) {
        if (
            IRandomNumGenerator(randomGen).getRandomNumber(
                businessHolders.length + seed,
                100,
                block.timestamp
            ) >= 10
        ) {
            return msg.sender;
        }

        address thief = randomBusinessOwner(businessHolders.length + seed);
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function _selectRecipientFromGangster(uint256 seed)
        private
        view
        returns (address)
    {
        if (
            IRandomNumGenerator(randomGen).getRandomNumber(
                gangsterHolders.length + seed,
                100,
                block.timestamp
            ) >= 10
        ) {
            return msg.sender;
        }

        address thief = randomGangsterOwner(gangsterHolders.length + seed);
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function randomBusinessOwner(uint256 seed) public view returns (address) {
        if (businessHolders.length == 0) return address(0x0);

        uint256 holderIndex = IRandomNumGenerator(randomGen).getRandomNumber(
            businessHolders.length + seed,
            businessHolders.length,
            block.timestamp
        );

        return businessHolders[holderIndex];
    }

    function randomGangsterOwner(uint256 seed) public view returns (address) {
        if (gangsterHolders.length == 0) return address(0x0);

        uint256 holderIndex = IRandomNumGenerator(randomGen).getRandomNumber(
            gangsterHolders.length + seed,
            gangsterHolders.length,
            block.timestamp
        );

        return gangsterHolders[holderIndex];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}