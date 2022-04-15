pragma solidity 0.8.13;

import "../interfaces/IOraclesManager.sol";

/**
 * @title TemplateSetLibrary
 * @dev A library to handle template changes/updates.
 * @author Federico Luzzi <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library OracleTemplateSetLibrary {
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error TemplateAlreadyAdded();
    error NonExistentTemplate();
    error NoKeyForTemplate();
    error NotAnUpgrade();
    error InvalidIndices();
    error InvalidVersionBump();

    function contains(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public view returns (bool) {
        return _self.map[_id].exists;
    }

    function get(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public view returns (IOraclesManager.Template storage) {
        if (!contains(_self, _id)) revert NonExistentTemplate();
        return _self.map[_id];
    }

    function add(
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template,
        bool _automatable,
        string calldata _specification
    ) public {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = _self.ids++;
        _self.map[_id] = IOraclesManager.Template({
            id: _id,
            addrezz: _template,
            version: IOraclesManager.Version({major: 1, minor: 0, patch: 0}),
            specification: _specification,
            automatable: _automatable,
            exists: true
        });
        _self.keys.push(_id);
    }

    function remove(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public {
        IOraclesManager.Template storage _templateFromStorage = get(_self, _id);
        delete _templateFromStorage.exists;
        uint256 _keysLength = _self.keys.length;
        for (uint256 _i = 0; _i < _keysLength; _i++)
            if (_self.keys[_i] == _id) {
                if (_i != _keysLength - 1)
                    _self.keys[_i] = _self.keys[_keysLength - 1];
                _self.keys.pop();
                return;
            }
        revert NoKeyForTemplate();
    }

    function upgrade(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        IOraclesManager.Template storage _templateFromStorage = get(_self, _id);
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        _templateFromStorage.addrezz = _newTemplate;
        _templateFromStorage.specification = _newSpecification;
        if (_versionBump & 1 == 1) _templateFromStorage.version.patch++;
        else if (_versionBump & 2 == 2) {
            _templateFromStorage.version.minor++;
            _templateFromStorage.version.patch = 0;
        } else if (_versionBump & 4 == 4) {
            _templateFromStorage.version.major++;
            _templateFromStorage.version.minor = 0;
            _templateFromStorage.version.patch = 0;
        } else revert InvalidVersionBump();
    }

    function size(IOraclesManager.EnumerableTemplateSet storage _self)
        external
        view
        returns (uint256)
    {
        return _self.keys.length;
    }

    function enumerate(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _fromIndex,
        uint256 _toIndex
    ) external view returns (IOraclesManager.Template[] memory) {
        if (_toIndex > _self.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IOraclesManager.Template[]
            memory _templates = new IOraclesManager.Template[](_range);
        for (uint256 _i = _fromIndex; _i < _fromIndex + _range; _i++) {
            _templates[_i] = _self.map[_self.keys[_i]];
        }
        return _templates;
    }
}

pragma solidity >0.8.0;

/**
 * @title IOraclesManager
 * @dev IOraclesManager contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOraclesManager {
    struct Version {
        uint32 major;
        uint32 minor;
        uint32 patch;
    }

    struct Template {
        uint256 id;
        address addrezz;
        Version version;
        string specification;
        bool automatable;
        bool exists;
    }

    struct EnumerableTemplateSet {
        uint256 ids;
        mapping(uint256 => Template) map;
        uint256[] keys;
    }

    function setJobsRegistry(address _jobsRegistry) external;

    function predictInstanceAddress(
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external returns (address);

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external;

    function removeTemplate(uint256 _id) external;

    function updgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function templatesAmount() external view returns (uint256);

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}