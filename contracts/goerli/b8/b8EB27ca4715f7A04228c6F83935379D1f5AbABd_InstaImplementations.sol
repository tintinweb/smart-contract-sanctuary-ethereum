pragma solidity 0.8.10;

interface IFactory {
    function ownerOfDSA(address _dsa) external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFactory} from "../../IFactory.sol";

contract Setup {
    address public defaultImplementation;

    mapping(bytes4 => address) internal sigImplementations;

    mapping(address => bytes4[]) internal implementationSigs;
}

contract Implementations is Setup {
    event LogSetDefaultImplementation(
        address indexed oldImplementation,
        address indexed newImplementation
    );
    event LogAddImplementation(address indexed implementation, bytes4[] sigs);
    event LogRemoveImplementation(
        address indexed implementation,
        bytes4[] sigs
    );

    IFactory public immutable factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }

    modifier isOwner() {
        require(msg.sender == factory.owner(), "Implementations: not-owner");
        _;
    }

    function setDefaultImplementation(address _defaultImplementation)
        external
        isOwner
    {
        require(
            _defaultImplementation != address(0),
            "Implementations: _defaultImplementation address not valid"
        );
        require(
            _defaultImplementation != defaultImplementation,
            "Implementations: _defaultImplementation cannot be same"
        );
        emit LogSetDefaultImplementation(
            defaultImplementation,
            _defaultImplementation
        );
        defaultImplementation = _defaultImplementation;
    }

    function addImplementation(address _implementation, bytes4[] calldata _sigs)
        external
        isOwner
    {
        require(
            _implementation != address(0),
            "Implementations: _implementation not valid."
        );
        require(
            implementationSigs[_implementation].length == 0,
            "Implementations: _implementation already added."
        );
        for (uint256 i = 0; i < _sigs.length; i++) {
            bytes4 _sig = _sigs[i];
            require(
                sigImplementations[_sig] == address(0),
                "Implementations: _sig already added"
            );
            sigImplementations[_sig] = _implementation;
        }
        implementationSigs[_implementation] = _sigs;
        emit LogAddImplementation(_implementation, _sigs);
    }

    function removeImplementation(address _implementation) external isOwner {
        require(
            _implementation != address(0),
            "Implementations: _implementation not valid."
        );
        require(
            implementationSigs[_implementation].length != 0,
            "Implementations: _implementation not found."
        );
        bytes4[] memory sigs = implementationSigs[_implementation];
        for (uint256 i = 0; i < sigs.length; i++) {
            bytes4 sig = sigs[i];
            delete sigImplementations[sig];
        }
        delete implementationSigs[_implementation];
        emit LogRemoveImplementation(_implementation, sigs);
    }
}

contract InstaImplementations is Implementations {
    constructor(address _factory) Implementations(_factory) {}

    function getImplementation(bytes4 _sig) external view returns (address) {
        address _implementation = sigImplementations[_sig];
        return
            _implementation == address(0)
                ? defaultImplementation
                : _implementation;
    }

    function getImplementationSigs(address _impl)
        external
        view
        returns (bytes4[] memory)
    {
        return implementationSigs[_impl];
    }

    function getSigImplementation(bytes4 _sig) external view returns (address) {
        return sigImplementations[_sig];
    }
}