pragma solidity 0.8.13;

import "../interfaces/IKPITokensManager.sol";

/**
 * @title KpiTokenTemplateSetLibrary
 * @dev A library to handle KPI token templates changes/updates.
 * @author Federico Luzzi <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library KpiTokenTemplateSetLibrary {
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error TemplateAlreadyAdded();
    error NonExistentTemplate();
    error NoKeyForTemplate();
    error NotAnUpgrade();
    error InvalidIndices();
    error InvalidVersionBump();

    function contains(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public view returns (bool) {
        return _self.map[_id].exists;
    }

    function get(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public view returns (IKPITokensManager.Template storage) {
        if (!contains(_self, _id)) revert NonExistentTemplate();
        return _self.map[_id];
    }

    function add(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template,
        string calldata _specification
    ) public {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = _self.ids++;
        _self.map[_id] = IKPITokensManager.Template({
            id: _id,
            addrezz: _template,
            version: IKPITokensManager.Version({major: 1, minor: 0, patch: 0}),
            specification: _specification,
            exists: true
        });
        _self.keys.push(_id);
    }

    function remove(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _id
    ) public {
        IKPITokensManager.Template storage _templateFromStorage = get(
            _self,
            _id
        );
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
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external {
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        IKPITokensManager.Template storage _templateFromStorage = get(
            _self,
            _id
        );
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

    function size(IKPITokensManager.EnumerableTemplateSet storage _self)
        external
        view
        returns (uint256)
    {
        return _self.keys.length;
    }

    function enumerate(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _fromIndex,
        uint256 _toIndex
    ) external view returns (IKPITokensManager.Template[] memory) {
        if (_toIndex > _self.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IKPITokensManager.Template[]
            memory _templates = new IKPITokensManager.Template[](_range);
        for (uint256 _i = _fromIndex; _i < _fromIndex + _range; _i++) {
            _templates[_i] = _self.map[_self.keys[_i]];
        }
        return _templates;
    }
}

pragma solidity >0.8.0;

/**
 * @title IKPITokensManager
 * @dev IKPITokensManager contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPITokensManager {
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
        bool exists;
    }

    struct EnumerableTemplateSet {
        uint256 ids;
        mapping(uint256 => Template) map;
        uint256[] keys;
    }

    function predictInstanceAddress(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address);

    function addTemplate(address _template, string calldata _specification)
        external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
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