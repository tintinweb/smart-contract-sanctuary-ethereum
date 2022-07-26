/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity 0.6.7;

library OperatorManagerLibrary {
    struct OperatorAuthorization {
        uint256 operatorRole;
    }

    struct OperatorManager {
        mapping(address => OperatorAuthorization[]) authorizationsByOperator;
    }

    event NewOperator(address _by, address _operator, uint256 _operatorRole);
    event RevokeOperator(address _by, address _operator, uint256 _operatorRole);

    function authorizeOperator(
        OperatorManager storage operatorManager,
        uint256 _operatorRole,
        address _operator
    ) external {
        OperatorAuthorization memory operatorAuthorization;
        operatorAuthorization.operatorRole = _operatorRole;
        operatorManager.authorizationsByOperator[_operator].push(
            operatorAuthorization
        );

        emit NewOperator(msg.sender, _operator, _operatorRole);
    }

    function isOperatorWithRoleAuthorized(
        OperatorManager storage operatorManager,
        address _operator,
        uint256 _operatorRole
    ) external view returns (bool) {
        OperatorAuthorization[] storage operatorAuthorizations =
            operatorManager.authorizationsByOperator[_operator];

        for (uint256 i = 0; i < operatorAuthorizations.length; i++) {
            if (operatorAuthorizations[i].operatorRole == _operatorRole) {
                return true;
            }
        }
        return false;
    }

    function revokeOperatorAuthorization(
        OperatorManager storage operatorManager,
        address _operator,
        uint256 _operatorRole
    ) external {
        OperatorAuthorization[] storage operatorAuthorizations =
            operatorManager.authorizationsByOperator[_operator];

        for (uint256 i = 0; i < operatorAuthorizations.length; i++) {
            if (operatorAuthorizations[i].operatorRole == _operatorRole) {
                delete operatorAuthorizations[i];
                emit RevokeOperator(msg.sender, _operator, _operatorRole);
                return;
            }
        }

        revert("Can not revoke role : target does not have role");
    }
}