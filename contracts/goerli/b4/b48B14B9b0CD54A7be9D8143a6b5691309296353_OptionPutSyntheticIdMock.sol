// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../../../interfaces/IDerivativeLogic.sol";
import "../../../helpers/ExecutableByThirdParty.sol";
import "../../../helpers/HasCommission.sol";

contract OptionPutSyntheticIdMock is IDerivativeLogic, ExecutableByThirdParty, HasCommission {
    uint256 constant BASE_PPT = 1 ether;

    constructor() {
        emit LogMetadataSet(
            '{"author":"OpiumDAO","type":"option","subtype":"put","description":"PUT option mock"}'
        );
    }

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external pure override returns (string memory) {
        return "Riccardo's derivative shop";
    }

    /// @notice Getter for syntheticId author address
    /// @return address syntheticId author address
    function getAuthorAddress() public view virtual override(IDerivativeLogic, HasCommission) returns (address) {
        return HasCommission.getAuthorAddress();
    }

    /// @notice Getter for syntheticId author commission
    /// @return uint26 syntheticId author commission
    function getAuthorCommission() public view override(IDerivativeLogic, HasCommission) returns (uint256) {
        return HasCommission.getAuthorCommission();
    }

    function validateInput(LibDerivative.Derivative calldata _derivative) external view override returns (bool) {
        if (_derivative.params.length < 1) {
            return false;
        }

        uint256 ppt;

        if (_derivative.params.length == 2) {
            ppt = _derivative.params[1];
        } else {
            ppt = BASE_PPT;
        }

        uint256 strikePrice = _derivative.params[0];
        return (_derivative.margin > 0 && _derivative.endTime > block.timestamp && strikePrice > 0 && ppt > 0);
    }

    function getMargin(LibDerivative.Derivative calldata _derivative)
        external
        pure
        override
        returns (uint256 buyerMargin, uint256 sellerMargin)
    {
        buyerMargin = 0;
        sellerMargin = _derivative.margin;
    }

    function getExecutionPayout(LibDerivative.Derivative calldata _derivative, uint256 _result)
        external
        pure
        override
        returns (uint256 buyerPayout, uint256 sellerPayout)
    {
        uint256 ppt;

        uint256 strikePrice = _derivative.params[0];

        if (_derivative.params.length == 2) {
            ppt = _derivative.params[1];
        } else {
            ppt = BASE_PPT;
        }

        if (_result < strikePrice) {
            uint256 profit = strikePrice - _result;
            profit = (profit * ppt) / BASE_PPT;

            if (profit < _derivative.margin) {
                buyerPayout = profit;
                sellerPayout = _derivative.margin - profit;
            } else {
                buyerPayout = _derivative.margin;
                sellerPayout = 0;
            }
        } else {
            buyerPayout = 0;
            sellerPayout = _derivative.margin;
        }
    }

    function allowThirdpartyExecution(bool allow) public virtual override(IDerivativeLogic, ExecutableByThirdParty) {
        ExecutableByThirdParty.allowThirdpartyExecution(allow);
    }

    function thirdpartyExecutionAllowed(address derivativeOwner)
        public
        view
        virtual
        override(IDerivativeLogic, ExecutableByThirdParty)
        returns (bool)
    {
        return ExecutableByThirdParty.thirdpartyExecutionAllowed(derivativeOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../libs/LibDerivative.sol";

/// @title Opium.Interface.IDerivativeLogic is an interface that every syntheticId should implement
interface IDerivativeLogic {
    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event LogMetadataSet(string metadata);

    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(LibDerivative.Derivative memory _derivative) external view returns (bool);

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external view returns (string memory);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(LibDerivative.Derivative memory _derivative)
        external
        view
        returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(LibDerivative.Derivative memory _derivative, uint256 _result)
        external
        view
        returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() external view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() external view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) external view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Helpers.ExecutableByThirdParty contract helps to syntheticId development and responsible for getting and setting thirdparty execution settings
abstract contract ExecutableByThirdParty {
    // Mapping holds whether position owner allows thirdparty execution
    mapping(address => bool) private thirdpartyExecutionAllowance;

    /// @notice Getter for thirdparty execution allowance
    /// @param derivativeOwner Address of position holder that's going to be executed
    /// @return bool Returns whether thirdparty execution is allowed by derivativeOwner
    function thirdpartyExecutionAllowed(address derivativeOwner) public view virtual returns (bool) {
        return thirdpartyExecutionAllowance[derivativeOwner];
    }

    /// @notice Sets third party execution settings for `msg.sender`
    /// @param allow Indicates whether thirdparty execution should be allowed or not
    function allowThirdpartyExecution(bool allow) public virtual {
        thirdpartyExecutionAllowance[msg.sender] = allow;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Helpers.HasCommission contract helps to syntheticId development and responsible for commission and author address
abstract contract HasCommission {
    // Address of syntheticId author
    address private author;
    // Commission is in Opium.Lib.LibCommission.COMMISSION_BASE base
    uint256 private constant AUTHOR_COMMISSION = 25; // 0.25% of profit

    /// @notice Sets `msg.sender` as syntheticId author
    constructor() {
        author = msg.sender;
    }

    /// @notice Getter for syntheticId author address
    /// @return address syntheticId author address
    function getAuthorAddress() public view virtual returns (address) {
        return author;
    }

    /// @notice Getter for syntheticId author commission
    /// @return uint26 syntheticId author commission
    function getAuthorCommission() public view virtual returns (uint256) {
        return AUTHOR_COMMISSION;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}