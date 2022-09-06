pragma solidity ^0.8.0;

import "../contracts/proxy/TokenProxy.sol";

contract OasisDevProxy is TokenProxy {
    constructor(
        address _implementationAuthority,
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _valuation,
        uint _initialSupply
    ) TokenProxy(
        _implementationAuthority,
        _identityRegistry,
        _compliance,
        _name,
        _symbol,
        _decimals,
        0x0000000000000000000000000000000000000000,
        _valuation,
        _initialSupply
    ){}
}

// SPDX-License-Identifier: GPL-3.0
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface IImplementationAuthority {
    function getImplementation() external view returns (address);
}

contract TokenProxy {
    address public implementationAuthority;

    constructor(
        address _implementationAuthority,
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID,
        uint _valuation,
        uint _initSupply
    ) {
        implementationAuthority = _implementationAuthority;

        address logic = IImplementationAuthority(implementationAuthority).getImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) =
            logic.delegatecall(
                abi.encodeWithSignature(
                    'init(address,address,string,string,uint8,address,uint256,uint256)',
                    _identityRegistry,
                    _compliance,
                    _name,
                    _symbol,
                    _decimals,
                    _onchainID,
                    _valuation,
                    _initSupply
                )
            );
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = IImplementationAuthority(implementationAuthority).getImplementation();

        assembly {
            // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}