/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/DiscreetLog.sol

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


// import "@openzeppelin/contracts/access/AccessControl.sol";

contract DiscreetLog {
    string[] public openUUIDs;
    mapping(string => DLC) public dlcs;

    mapping(uint256 => Loan) public loans;
    uint256 public numLoans = 0;

    mapping(address => uint256) public loansPerAddress;

    enum Status {
        NotReady,
        Ready,
        Funded,
        PreRepaid,
        Repaid,
        PreLiquidated,
        Liquidated
    }

    Status public status;
    mapping(Status => string) public statuses;

    struct DLC {
        string uuid;
        uint256 btcDeposit;
        uint256 liquidationRatio;
        uint256 liquidationFee;
        uint256 closingTime;
        int256 closingPrice;
        uint256 actualClosingTime;
        uint256 emergencyRefundTime;
        address creator;
    }

    struct Loan {
        uint256 id;
        string dlc_uuid;
        string status;
        uint256 vaultLoan; // the borrowed amount
        uint256 vaultCollateral; // btc deposit in sats
        uint256 liquidationRatio; // the collateral/loan ratio below which liquidation can happen, with two decimals precision (140% = u14000)
        uint256 liquidationFee; // additional fee taken during liquidation, two decimals precision (10% = u1000)
        uint256 closingPrice; // In case of liquidation, the closing BTC price will be stored here
        address owner; // the stacks account owning this loan
    }

    constructor() {
        statuses[Status.NotReady] = "not-ready";
        statuses[Status.Ready] = "ready";
        statuses[Status.Funded] = "funded";
        statuses[Status.PreRepaid] = "pre-repaid";
        statuses[Status.Repaid] = "repaid";
        statuses[Status.PreLiquidated] = "pre-liquidated";
        statuses[Status.Liquidated] = "liquidated";
    }

    // An example function to initiate the creation of a DLC loan.
    // - Increments the loan-id
    // - Calls the dlc-manager-contract's create-dlc function to initiate the creation
    // The DLC Contract will call back into the provided 'target' contract with the resulting UUID (and the provided loan-id).
    // Currently this 'target' must be the same contract as the one initiating the process, for authentication purposes.
    // See scripts/setup-loan.ts for an example of calling it.
    function setupLoan(
        uint256 vaultLoanAmount,
        uint256 btcDeposit,
        uint256 liquidationRatio,
        uint256 liquidationFee,
        uint256 emergencyRefundTime
    )
        external returns (uint256)
    {
        loans[numLoans] = Loan({
            id: numLoans,
            dlc_uuid: "",
            status: statuses[Status.NotReady],
            vaultLoan: vaultLoanAmount,
            vaultCollateral: btcDeposit,
            liquidationRatio: liquidationRatio,
            liquidationFee: liquidationFee,
            closingPrice: 0,
            owner: msg.sender
        });

        createDlc(
            vaultLoanAmount,
            btcDeposit,
            liquidationRatio,
            liquidationFee,
            msg.sender,
            emergencyRefundTime,
            numLoans
        );
        loansPerAddress[msg.sender]++;
        numLoans++;
        return(numLoans - 1);
    }

    event CreateDLC(
        uint256 vaultLoanAmount,
        uint256 btcDeposit,
        uint256 liquidationRatio,
        uint256 liquidationFee,
        address creator,
        uint256 emergencyRefundTime,
        uint256 nonce,
        string eventSource
    );

    function createDlc(
        uint256 _vaultLoanAmount,
        uint256 _btcDeposit,
        uint256 _liquidationRatio,
        uint256 _liquidationFee,
        address _creator,
        uint256 _emergencyRefundTime,
        uint256 _nonce
    ) public {
        emit CreateDLC(
            _vaultLoanAmount,
            _btcDeposit,
            _liquidationRatio,
            _liquidationFee,
            _creator,
            _emergencyRefundTime,
            _nonce,
            "dlclink:create-dlc:v0"
        );
    }

    event CreateDLCInternal(
        string uuid,
        uint256 btcDeposit,
        uint256 liquidationRatio,
        uint256 liquidationFee,
        uint256 emergencyRefundTime,
        address creator,
        string eventSource
    );

    function createDLCInternal(
        string memory _uuid,
        uint256 _btcDeposit,
        uint256 _liquidationRatio,
        uint256 _liquidationFee,
        uint256 _emergencyRefundTime,
        address _creator,
        uint256 _nonce
    ) external {
        dlcs[_uuid] = DLC({
            uuid: _uuid,
            btcDeposit: _btcDeposit,
            liquidationRatio: _liquidationRatio,
            liquidationFee: _liquidationFee,
            closingPrice: 0,
            closingTime: _emergencyRefundTime,
            actualClosingTime: 0,
            emergencyRefundTime: _emergencyRefundTime,
            creator: _creator
        });
        openUUIDs.push(_uuid);
        loans[_nonce].dlc_uuid = _uuid;
        loans[_nonce].status = statuses[Status.Ready];
        emit CreateDLCInternal(
            _uuid,
            _btcDeposit,
            _liquidationRatio,
            _liquidationFee,
            _emergencyRefundTime,
            _creator,
            "dlclink:create-dlc-internal:v0"
        );
    }

    event SetStatusFunded(string uuid, string eventSource);

    function setStatusFunded(string memory _uuid) external {
        loans[findLoanIndex(_uuid)].status = statuses[Status.Funded];
        emit SetStatusFunded(_uuid, "dlclink:set-status-funded:v0");
    }

    event CloseDLC(
        string uuid,
        int256 payoutRatio,
        int256 closingPrice,
        uint256 actualClosingTime
    );

    //     (define-public (repay-loan (loan-id uint))
    //   (let (
    //     (loan (unwrap! (get-loan loan-id) err-unknown-loan-contract))
    //     (uuid (unwrap! (get dlc_uuid loan) err-cant-unwrap))
    //     )
    //     (begin
    //       (map-set loans loan-id (merge loan { status: status-pre-repaid }))
    //       (print { uuid: uuid, status: status-pre-repaid })
    //       (unwrap! (ok (as-contract (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.dlc-manager-loan-v0 close-dlc uuid))) err-contract-call-failed)
    //     )
    //   )
    // )

    function repayLoan(uint256 loanId) external {
        closeDlc(loans[loanId].dlc_uuid);
        loans[loanId].status = statuses[Status.PreRepaid];
    }

    function liquidateLoan(uint256 loanId) external {
        closeDlcLiquidate(loans[loanId].dlc_uuid);
        loans[loanId].status = statuses[Status.PreRepaid];
    }

    function closeDlc(string memory _uuid) public {
        DLC storage dlc = dlcs[_uuid];
        require(
            dlc.closingTime <= block.timestamp && dlc.actualClosingTime == 0,
            "Validation failed for closeDlc"
        );

        int256 payoutRatio = 0; //This is where the loan stuff goes
        removeClosedDLC(findIndex(_uuid));
        emit CloseDLC(_uuid, payoutRatio, 0, block.timestamp);
    }

    function closeDlcLiquidate(string memory _uuid) public {
        DLC storage dlc = dlcs[_uuid];
        require(
            dlc.closingTime <= block.timestamp && dlc.actualClosingTime == 0,
            "Validation failed for closeDlc"
        );

        (int256 price, uint256 timestamp) = getLatestPrice(
            address(0xA39434A63A52E749F02807ae27335515BA4b07F7)
        );
        dlc.closingPrice = price;
        // int256 payoutRatio = dlc.strikePrice > price ? int256(0) : int256(1);
        int256 payoutRatio = 0; //This is where the loan stuff goes

        removeClosedDLC(findIndex(_uuid));
        emit CloseDLC(_uuid, payoutRatio, price, timestamp);
    }

    // function closingPriceAndTimeOfDLC(string memory _uuid)
    //     external
    //     view
    //     returns (int256, uint256)
    // {
    //     DLC memory dlc = dlcs[_uuid];
    //     require(
    //         dlc.actualClosingTime > 0,
    //         "The requested DLC is not closed yet"
    //     );
    //     return (dlc.closingPrice, dlc.actualClosingTime);
    // }

    // function allOpenDLC() external view returns (string[] memory) {
    //     return openUUIDs;
    // }

    function getLatestPrice(address _feedAddress)
        internal
        view
        returns (int256, uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_feedAddress);
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();
        return (price, timeStamp);
    }

    // note: this remove not preserving the order
    function removeClosedDLC(uint256 index) private returns (string[] memory) {
        require(index < openUUIDs.length);
        // Move the last element to the deleted spot
        openUUIDs[index] = openUUIDs[openUUIDs.length - 1];
        // Remove the last element
        openUUIDs.pop();
        return openUUIDs;
    }

    function findIndex(string memory _uuid) private view returns (uint256) {
        // find the recently closed uuid index
        for (uint256 i = 0; i < openUUIDs.length; i++) {
            if (
                keccak256(abi.encodePacked(openUUIDs[i])) ==
                keccak256(abi.encodePacked(_uuid))
            ) {
                return i;
            }
        }
        revert("Not Found"); // should not happen just in case
    }

    function getAllLoansForAddress(address _addy) public view returns (Loan[] memory) {
        Loan[] memory ownedLoans = new Loan[](loansPerAddress[_addy]);
        uint256 j = 0;
        for (uint256 i = 0; i < numLoans; i++) {
            if (loans[i].owner == _addy) {
                ownedLoans[j++] = loans[i];
            }
        }
        return ownedLoans;
    }

    function findLoanIndex(string memory _uuid) private view returns (uint256) {
        // find the recently closed uuid index
        for (uint256 i = 0; i < numLoans; i++) {
            if (
                keccak256(abi.encodePacked(loans[i].dlc_uuid)) ==
                keccak256(abi.encodePacked(_uuid))
            ) {
                return i;
            }
        }
        revert("Not Found"); // should not happen just in case
    }

    function getAllUUIDs() public view returns (string[] memory) {
        // string[] memory allUUIDs = new string[](openUUIDs.length);
        // for (uint256 i = 0; i < openUUIDs.length; i++) {
        //     allUUIDs[i] = openUUIDs[i];
        // }
        // return allUUIDs;
        return openUUIDs;
    }
}