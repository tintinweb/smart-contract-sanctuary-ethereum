//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/IKeyProtocolVariables.sol";

contract KeyProtocolVariables is IKeyProtocolVariables {
    address public dao;

    bool public preLaunch = true;

    //Commisions
    uint256 public xTokenMintFee = 300; // 3%
    uint256 public cTokenSellFee = 1000; // 10%
    uint256 public payRentFee = 150; // 1.5%

    uint256 public validatorCommission = 25; // 0.25%
    uint256 public maxValidatorFee = 1000;

    uint256 public sellXTokenSlippage = 300; //3%
    uint256 public buyXTokenSlippage = 300; //3%

    uint256 public hedgeFundAllocation = 1500; //15%
    uint8 public securityDepositMonths = 12; // 12 months

    uint256 public landXOperationsPercentage = 3000;
    uint256 public landXChoicePercentage = 500;
    uint256 public lndxHoldersPercentage = 6500;

    // Wallets
    address public hedgeFundWallet;
    address public landxOperationalWallet;
    address public landxChoiceWallet;
    address public xTokensSecurityWallet;
    address public validatorCommisionWallet;

    constructor(
        address _dao,
        address _hedgeFundWallet,
        address _landxOperationalWallet,
        address _landxChoiceWallet,
        address _xTokensSecurityWallet,
        address _validatorCommisionWallet
    ) {
        dao = _dao;

        require(_hedgeFundWallet != address(0), "zero address is not allowed");
        require(_landxOperationalWallet != address(0), "zero address is not allowed");
        require(_landxChoiceWallet != address(0), "zero address is not allowed");
        require(_xTokensSecurityWallet != address(0), "zero address is not allowed");
        require(_validatorCommisionWallet != address(0), "zero address is not allowed");

        hedgeFundWallet = _hedgeFundWallet;
        landxOperationalWallet = _landxOperationalWallet;
        landxChoiceWallet = _landxChoiceWallet;
        xTokensSecurityWallet = _xTokensSecurityWallet;
        validatorCommisionWallet = _validatorCommisionWallet;
    }

    function updateXTokenMintFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        xTokenMintFee = _fee;
    }

    function updateCTokenSellFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        cTokenSellFee = _fee;
    }

    function updateValidatorCommission(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        validatorCommission = _fee;
    }

     function updateMaxValidatorFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        maxValidatorFee = _fee;
    }

    function updateSellXTokenSlippage(uint256 _slippage) public {
        require(msg.sender == dao, "only dao can change value");
        require(_slippage < 10000, "value can't be above 100%");
        sellXTokenSlippage = _slippage;
    }

    function updateBuyXTokenSlippage(uint256 _slippage) public {
        require(msg.sender == dao, "only dao can change value");
        require(_slippage < 10000, "value can't be above 100%");
        buyXTokenSlippage = _slippage;
    }

    function updatePayRentFee(uint256 _fee) public {
        require(msg.sender == dao, "only dao can change value");
        require(_fee < 10000, "value can't be above 100%");
        payRentFee = _fee;
    }

    function updateHedgeFundAllocation(uint256 _allocation) public {
        require(msg.sender == dao, "only dao can change value");
        require(_allocation < 10000, "value can't be above 100%");
        hedgeFundAllocation = _allocation;
    }

    function updateSecurityDepositMonths(uint8 _months) public {
        require(msg.sender == dao, "only dao can change value");
        securityDepositMonths = _months;
    }

    function updateFeeDistributionPercentage(
        uint256 _lndxHoldersPercentage,
        uint256 _landxOperationPercentage
    ) public {
        require(msg.sender == dao, "only dao can change value");
        require(
            (_lndxHoldersPercentage + _landxOperationPercentage) < 10000,
            "inconsistent values"
        );
        lndxHoldersPercentage = _lndxHoldersPercentage;
        landXOperationsPercentage = _landxOperationPercentage;
        landXChoicePercentage =
            10000 -
            lndxHoldersPercentage -
            landXOperationsPercentage;
    }

    function updateHedgeFundWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        hedgeFundWallet = _wallet;
    }

    function updateLandxOperationalWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        landxOperationalWallet = _wallet;
    }

    function updateLandxChoiceWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        landxChoiceWallet = _wallet;
    }

    function updateXTokensSecurityWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        xTokensSecurityWallet = _wallet;
    }

    function updateValidatorCommisionWallet(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        validatorCommisionWallet = _wallet;
    }

    function updateDao(address _wallet) public {
        require(msg.sender == dao, "only dao can change value");
        require(_wallet != address(0), "zero address is not allowed");
        dao = _wallet;
    }

    function launch() public {
        require(msg.sender == dao, "only dao can change value");
        preLaunch = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IKeyProtocolVariables {
    function xTokenMintFee() external view returns (uint256);

    function securityDepositMonths() external view returns (uint8);

    function xTokensSecurityWallet() external view returns (address);

    function landxOperationalWallet() external view returns (address);

    function landxChoiceWallet() external view returns (address);

    function landXOperationsPercentage() external view returns (uint256);

    function landXChoicePercentage() external view returns (uint256);

    function lndxHoldersPercentage() external view returns (uint256);

    function hedgeFundAllocation() external view returns (uint256);

    function hedgeFundWallet() external view returns (address);

    function preLaunch() external view returns (bool);

    function sellXTokenSlippage() external view returns (uint256);
   
    function buyXTokenSlippage() external view returns (uint256);  

    function cTokenSellFee() external view returns (uint256);

    function validatorCommission() external view returns (uint256);

    function validatorCommisionWallet() external view returns (address);

    function payRentFee() external view returns (uint256);

    function maxValidatorFee() external view returns (uint256);
}