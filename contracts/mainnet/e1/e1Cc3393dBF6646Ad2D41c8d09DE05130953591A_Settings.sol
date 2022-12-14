// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "./interface/Icontroller.sol";

contract Settings {
    IController public controller;
    mapping(uint256 => uint256) public networkGas;

    address payable public feeRemitance;
    address payable public gasBank;
    uint256 public railRegistrationFee = 5000 * 10**18;
    uint256 public railOwnerFeeShare = 20;
    uint256 public minWithdrawableFee = 1 * 10**17;
    uint256 public constant minValidationPercentage = 51;
    uint256 public maxFeeThreshold = 1000; // this varaiable is only
    uint256 public ValidationPercentage = minValidationPercentage;
    bool public onlyOwnableRail = true;
    bool public updatableAssetState = true;
    address public brgToken;
    uint256[] public networkSupportedChains;

    uint256 public baseFeePercentage = 10;
    bool public baseFeeEnable;
    mapping(uint256 => bool) public isNetworkSupportedChain;
    mapping(address => mapping(address => bool)) public approvedToAdd;

    event ApprovedToAdd(
        address indexed token,
        address indexed user,
        bool status
    );
    event MinValidationPercentageUpdated(
        uint256 prevMinValidationPercentage,
        uint256 newMinValidationPercentage
    );
    event BrdgTokenUpdated(address indexed prevValue, address indexed newValue);
    event minWithdrawableFeeUpdated(uint256 prevValue, uint256 newValue);
    event FeeRemitanceAddressUpdated(
        address indexed prevValue,
        address indexed newValue
    );
    event GasBankUpdated(address indexed prevValue, address indexed newValue);
    event RailRegistrationFeeUpdated(uint256 prevValue, uint256 newValue);
    event RailOwnerFeeShareUpdated(uint256 prevValue, uint256 newValue);
    event NetworkGasUpdated(
        uint256 chainId,
        uint256 prevValue,
        uint256 newValue
    );
    event BaseFeePercentageUpdated(uint256 prevValue, uint256 newValue);
    event NetworkSupportedChainsUpdated(uint256[] chains, bool isadded);
    event UpdatableAssetStateChanged(bool status);
    event OnlyOwnableRailStateEnabled(bool status);
    event BaseFeeStatusChanged(bool baseFeeEnable);

    constructor(
        IController _controller,
        address payable _feeRemitance,
        address payable _gasBank
    ) {
        controller = _controller;
        feeRemitance = _feeRemitance;
        gasBank = _gasBank;
    }

    function setApprovedToAdd(address user, address token, bool status)
        external
    {
        onlyAdmin();
        require(approvedToAdd[token][user] != status, "same status");
        emit ApprovedToAdd(token, user, status);
        approvedToAdd[token][user] = status;
    }

    function setMinValidationPercentage(uint256 _ValidationPercentage)
        external
    {
        require(msg.sender == controller.owner(), "U_A");
        require(_ValidationPercentage != ValidationPercentage, "same");
        require(
            _ValidationPercentage > minValidationPercentage &&
                _ValidationPercentage <= 100,
            "valueERR"
        );
        emit MinValidationPercentageUpdated(
            ValidationPercentage,
            _ValidationPercentage
        );
        ValidationPercentage = _ValidationPercentage;
    }

    function setbaseFeePercentage(uint256 _base) external {
        require(msg.sender == controller.owner(), "U_A");
        require(_base < 1000, "exceed 10%");
        emit BaseFeePercentageUpdated(baseFeePercentage, _base);
        baseFeePercentage = _base;
    }

    function enableBaseFee() external {
        require(msg.sender == controller.owner(), "U_A");
        baseFeeEnable = !baseFeeEnable;
        emit BaseFeeStatusChanged(baseFeeEnable);
    }

    function setbrgToken(address token) external {
        onlyAdmin();
        require(token != address(0), "zero_A");
        emit BrdgTokenUpdated(token, token);
        brgToken = token;
    }

    function setminWithdrawableFee(uint256 _minWithdrawableFee) external {
        onlyAdmin();
        require(_minWithdrawableFee > 0, "valueERR");
        emit minWithdrawableFeeUpdated(minWithdrawableFee, _minWithdrawableFee);
        minWithdrawableFee = _minWithdrawableFee;
    }

    function setNetworkSupportedChains(
        uint256[] memory chains,
        uint256[] memory fees,
        bool addchain
    ) external {
        onlyAdmin();
        uint256 id = getChainId();

        uint256 chainLenght = chains.length;
        uint256 feeLenght = fees.length;
        if (addchain) {
            require(chainLenght == feeLenght, "invalid");

            for (uint256 index; index < chainLenght; index++) {
                if (
                    !isNetworkSupportedChain[chains[index]] &&
                    chains[index] != id
                ) {
                    networkSupportedChains.push(chains[index]);
                    isNetworkSupportedChain[chains[index]] = true;
                    networkGas[chains[index]] = fees[index];
                } else if (isNetworkSupportedChain[chains[index]]) {
                    networkGas[chains[index]] = fees[index];
                }
            }
        } else {
            for (uint256 index; index < chainLenght; index++) {
                if (isNetworkSupportedChain[chains[index]]) {
                    for (
                        uint256 index1;
                        index1 < networkSupportedChains.length;
                        index1++
                    ) {
                        if (networkSupportedChains[index1] == chains[index]) {
                            networkSupportedChains[
                                index1
                            ] = networkSupportedChains[
                                networkSupportedChains.length - 1
                            ];
                            networkSupportedChains.pop();
                        }
                    }
                    networkGas[chains[index]] = 0;
                    isNetworkSupportedChain[chains[index]] = false;
                }
            }
        }
        emit NetworkSupportedChainsUpdated(chains, addchain);
    }

    function updateNetworkGas(uint256 chainId, uint256 fee) external {
        onlyAdmin();
        require(fee != networkGas[chainId], "sameVal");
        require(isNetworkSupportedChain[chainId], "not Supported");
        emit NetworkGasUpdated(chainId, networkGas[chainId], fee);
        networkGas[chainId] = fee;
    }

    function setRailOwnerFeeShare(uint256 share) external {
        onlyAdmin();
        require(railOwnerFeeShare != share, "sameVal");
        require(share > 1 && share < 100, "err");
        RailOwnerFeeShareUpdated(railOwnerFeeShare, share);
        railOwnerFeeShare = share;
    }

    function setUpdatableAssetState(bool status) external {
        onlyAdmin();
        require(status != updatableAssetState, "err");
        emit UpdatableAssetStateChanged(status);
        updatableAssetState = status;
    }

    function setOnlyOwnableRailState(bool status) external {
        onlyAdmin();
        require(status != onlyOwnableRail, "err");
        emit OnlyOwnableRailStateEnabled(status);
        onlyOwnableRail = status;
    }

    function setrailRegistrationFee(uint256 registrationFee) external {
        onlyAdmin();
        require(railRegistrationFee != registrationFee, "sameVal");
        emit RailRegistrationFeeUpdated(railRegistrationFee, registrationFee);
        railRegistrationFee = registrationFee;
    }

    function setFeeRemitanceAddress(address payable account) external {
        require(msg.sender == controller.owner(), "U_A");
        require(account != address(0), "zero_A");
        require(account != feeRemitance, "err");
        emit FeeRemitanceAddressUpdated(feeRemitance, account);
        feeRemitance = account;
    }

    function setGasBank(address payable _gasBank) external {
        require(msg.sender == controller.owner(), "U_A");
        require(_gasBank != address(0), "zero_A");
        require(_gasBank != gasBank, "err");
        emit GasBankUpdated(_gasBank, gasBank);
        gasBank = _gasBank;
    }

    function onlyAdmin() internal view {
        require(
            controller.isAdmin(msg.sender) || msg.sender == controller.owner(),
            "U_A"
        );
    }

    function minValidations() external view returns (uint256 minvalidation) {
        uint256 excludablePercentage = 100 - ValidationPercentage;
        uint256 excludableValidators = (controller.validatorsCount() *
            excludablePercentage) / 100;
        minvalidation = controller.validatorsCount() - excludableValidators;
    }

    function getNetworkSupportedChains()
        external
        view
        returns (uint256[] memory)
    {
        return networkSupportedChains;
    }

    function getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IController {
    function isAdmin(address account) external view returns (bool);

    function isRegistrar(address account) external view returns (bool);

    function isOracle(address account) external view returns (bool);

    function isValidator(address account) external view returns (bool);

    function owner() external view returns (address);

    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);

    function deployer() external view returns (address);

    function feeController() external view returns (address);
}