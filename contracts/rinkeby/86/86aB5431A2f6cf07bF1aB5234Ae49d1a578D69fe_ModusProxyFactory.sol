// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ModusProxy.sol";
import "./IProxyCreationCallback.sol";
import "../interfaces/IModusRegistry.sol";
import "../utils/Utility.sol";
import "../tokens/PXT.sol";
import "../interfaces/IStableCoinPXTSwap.sol";
import "../interfaces/IPXT.sol";
import "../interfaces/IPXTStaking.sol";
import "../interfaces/ITokenModusSwap.sol";

contract ModusProxyFactory is Utility {
    event ProxyCreation(ModusProxy proxy, address singleton);
    event ProjectAdvancement(
        uint256 indexed _projectId,
        uint256 indexed _newStage,
        uint256 _feePercentage,
        uint256 _schemeId,
        uint256 projectCapital,
        uint256 _premiumTImeframe,
        uint256 _lockinPeriod,
        address  _stablecoin,
        address  _proofVerifier
    );
    event ProjectAdvancement(
        uint256 indexed _projectId,
        uint256 indexed _newStage
    );
    event ProjectAdvancement(
        uint256 indexed _projectId,
        uint256 indexed _newStage,
        uint256 _mintpercentage,
        uint256 _operationalFee,
        uint256[] _conversionRates,
        address _operationalWallet
    );
   
    event ProjectAdvancement(
        uint256 indexed _projectId,
        uint256 indexed _newStage,
       uint pxtStableCoinConversionRate,
       uint pxrtStableCoinConversionRate
    );

    uint256 projectCounter;

    constructor(IModusRegistry _modusRegistry) Utility(_modusRegistry) {
        require(
            address(_modusRegistry) != address(0),
            "ModusProxyFactory: Zero Address"
        );
        modusRegistry = _modusRegistry;
    }

    ///@notice createProject allows Admin to create a new Project
    ///@param custodianWallet,feePercentage(percentage of reward tokens to be created ),
    ///schemeId(Reward scheme id for the project),stablecoinIndex(Index of ,Stable coin to be used in the project)
    function createProject(
        address custodianWallet,
        uint256[] memory details,
        address stableCoin,
        address proofVerifier
    ) external onlyModusAdmin {
        require(
            custodianWallet != address(0) && details[0] != 0 && details[1] != 0,
            "ModusProxyFactory: Zero as Input"
        );
        require(
            modusRegistry.isStableCoinSupported(stableCoin),
            "ModusProxyFactory: StableCoin not supported"
        );
        (uint256 scheme_id, , , ) = modusRegistry.getSchemeDetails(details[1]);
        require(
            scheme_id == details[1],
            "ModusProxyFactory: SchemeId not Supported"
        );
        projectCounter++;
        modusRegistry.setStableCoin(projectCounter, stableCoin);
        modusRegistry.setProjectDetails(
            projectCounter,
            1,
            abi.encode(custodianWallet, details[0], details[1]),
            abi.encode(
                address(
                    _createProxy(
                        modusRegistry.pxt(),
                        abi.encodeWithSignature(
                            "initialize(uint256,address,uint8)",
                            projectCounter,
                            address(modusRegistry),
                            ERC20(stableCoin).decimals()
                        )
                    )
                ),
                address(
                    _createProxy(
                        modusRegistry.stableCoinPXTSwap(),
                        abi.encodeWithSignature(
                            "initialize(uint256,uint256,uint256,address,address)",
                            projectCounter,
                            details[2],
                            details[3],
                            address(modusRegistry),
                            proofVerifier
                        )
                    )
                ),
                address(
                    _createProxy(
                        modusRegistry.pxtStaking(),
                        abi.encodeWithSignature(
                            "initialize(uint256,uint256,uint256,address)",
                            details[4],
                            details[2],
                            projectCounter,
                            address(modusRegistry)
                        )
                    )
                )
            )
        );
        emit ProjectAdvancement(
            projectCounter,
            1,
            details[0],
            details[1],
            details[2],
            details[3],
            details[4],
            stableCoin,
            proofVerifier
        );
    }

    ///@notice deployNextStage allows modus admin to move the project to next phase
    ///@param projectId, id of the project
    function deployNextStage(uint256 projectId, bytes memory data)
        external
        onlyModusAdmin
    {
        require(
            projectId <= projectCounter,
            "ModusProxyFactory: ProjectId Does not Exists"
        );
        uint256 projectStage = modusRegistry
            .getProjectDetails(projectId)
            .projectStage;
        require(projectStage < 4, "ModusProxyFactory: No Further Stage");
        if (projectStage == 1) {
            IStableCoinPXTSwap(
                modusRegistry.getProjectDetails(projectId)._stableCoinPXTSwap
            ).initiateSale();
            modusRegistry.setProjectDetails(projectId, 2, "0");
            //initiate pxt sales for the public investors
            emit ProjectAdvancement(projectId, 2);
        }
        if (projectStage == 2) {
            //_deployStage3(projectId, data);

            (
                uint256 operationalFee,
                uint256 pxtStableCoinconversionRate,
                uint256 pxrtStableCoinconversionRate,
                address operationalWallet
            ) = abi.decode(data, (uint256, uint256, uint256, address));

            uint256 schemeId = modusRegistry
                .getProjectDetails(projectId)
                .schemeId;
            (, , , uint256 mintpercentage) = modusRegistry.getSchemeDetails(
                schemeId
            );
            //console.log("PXRT MintPercentage",mintpercentage);
            IStableCoinPXTSwap(
                modusRegistry.getProjectDetails(projectId)._stableCoinPXTSwap
            ).endSale();
            IPXTStaking(modusRegistry.getProjectDetails(projectId)._pxtStaking)
                .beginEmission();

            uint256[] memory conversionRates = new uint256[](2);
            conversionRates[0] = pxtStableCoinconversionRate;
            conversionRates[1] = pxrtStableCoinconversionRate;

            _deployStage3(
                projectId,
                mintpercentage,
                operationalFee,
                conversionRates,
                operationalWallet
            );
            emit ProjectAdvancement(projectId, 3, mintpercentage,operationalFee,conversionRates,operationalWallet);
        }
        if (projectStage == 3) {
            (
                uint256 pxtStableCoinconversionRate,
                uint256 pxrtStableCoinconversionRate
            ) = abi.decode(data, (uint256, uint256));
            _deployStage4(
                projectId,
                pxtStableCoinconversionRate,
                pxrtStableCoinconversionRate
            );
            IPXTStaking(modusRegistry.getProjectDetails(projectId)._pxtStaking)
                .endProject();

            emit ProjectAdvancement(projectId, 4,pxtStableCoinconversionRate,pxrtStableCoinconversionRate);
        }
    }

    /// @notice In case of certain conditions admin can directly deploy stage 4
    /// @param projectId,pxtStableCoinconversionRate
    function directDeployStage4(
        uint256 projectId,
        uint256 pxtStableCoinconversionRate
    ) public onlyModusAdmin {
        require(
            projectId <= projectCounter,
            "ModusProxyFactory: ProjectId Does not Exists"
        );
        uint256 projectStage = modusRegistry
            .getProjectDetails(projectId)
            .projectStage;
        require(
            projectStage != 4,
            "ModusProxyFactory: Stage4 already deployed"
        );
        IPXTStaking(modusRegistry.getProjectDetails(projectId)._pxtStaking)
            .cancelProject();

        modusRegistry.setProjectDetails(
            projectId,
            4,
            abi.encode(
                address(
                    _createProxy(
                        modusRegistry.pxtStableCoinSwap(),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,uint256,address)",
                            address(modusRegistry),
                            projectId,
                            pxtStableCoinconversionRate,
                            modusRegistry.getProjectDetails(projectId)._pxt
                        )
                    )
                ),
                address(0)
            )
        );
        IPXTStaking(modusRegistry.getProjectDetails(projectId)._pxtStaking)
            .endProject();
        emit ProjectAdvancement(projectId,4,pxtStableCoinconversionRate,0);
    }

    function _deployStage3(
        uint256 projectId,
        uint256 mintpercentage,
        uint256 operationalFee,
        uint256[] memory conversionRates,
        address walletAddress
    ) internal {
        address pxt = modusRegistry.getProjectDetails(projectId)._pxt;
        uint256 mintvalue = ((IERC20(pxt).totalSupply() /
            (10**ERC20(pxt).decimals())) * mintpercentage) / (100 * 100); //mint percetage will have 2 decimal places

        modusRegistry.setProjectDetails(
            projectId,
            3,
            abi.encode(
                address(
                    _createProxy(
                        modusRegistry.pxrt(),
                        abi.encodeWithSignature(
                            "initialize(uint256,uint256,uint256,address,address,uint8)",
                            projectId,
                            mintvalue,
                            operationalFee,
                            walletAddress,
                            address(modusRegistry),
                            IPXT(pxt).decimals()
                        )
                    )
                ),
                address(
                    _createProxy(
                        modusRegistry.pxtModusSwap(),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,uint256)",
                            address(modusRegistry),
                            projectId,
                            conversionRates[0]
                        )
                    )
                ),
                address(
                    _createProxy(
                        modusRegistry.pxrtModusSwap(),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,uint256)",
                            address(modusRegistry),
                            projectId,
                            conversionRates[1]
                        )
                    )
                )
            )
        );

        ITokenModusSwap(
            modusRegistry.getProjectDetails(projectId)._pxtModusSwap
        ).setTokenAddress(pxt);
        ITokenModusSwap(
            modusRegistry.getProjectDetails(projectId)._pxrtModusSwap
        ).setTokenAddress(modusRegistry.getProjectDetails(projectId)._pxrt);
    }

    function _deployStage4(
        uint256 projectId,
        uint256 pxtStableCoinconversionRate,
        uint256 pxrtStableCoinconversionRate
    ) internal {
        modusRegistry.setProjectDetails(
            projectId,
            4,
            abi.encode(
                address(
                    _createProxy(
                        modusRegistry.pxtStableCoinSwap(),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,uint256,address)",
                            address(modusRegistry),
                            projectId,
                            pxtStableCoinconversionRate,
                            modusRegistry.getProjectDetails(projectId)._pxt
                        )
                    )
                ),
                address(
                    _createProxy(
                        modusRegistry.pxrtStableCoinSwap(),
                        abi.encodeWithSignature(
                            "initialize(address,uint256,uint256,address)",
                            address(modusRegistry),
                            projectId,
                            pxrtStableCoinconversionRate,
                            modusRegistry.getProjectDetails(projectId)._pxrt
                        )
                    )
                )
            )
        );
    }

    /// @notice Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function _createProxy(address singleton, bytes memory data)
        internal
        returns (ModusProxy proxy)
    {
        proxy = new ModusProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @notice Function allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(ModusProxy).runtimeCode;
    }

    /// @notice Function allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(ModusProxy).creationCode;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IProxy {
    function masterCopy() external view returns (address);
}

contract ModusProxy {
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        assembly {
            let _singleton := and(
                sload(0),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            if eq(
                calldataload(0),
                0xa619486e00000000000000000000000000000000000000000000000000000000
            ) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(
                gas(),
                _singleton,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./ModusProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        ModusProxy proxy,
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IModusRegistry {
    struct Scheme {
        uint256 schemeId;
        uint256 maxDays;
        uint256 exponentBase;
        uint256 percentageRewardTokens;
    }
    struct ModusProject {
        uint256 projectId;
        uint256 projectStage;
        address custodianWallet;
        uint256 feePercentage;
        uint256 schemeId;
        address _stableCoinPXTSwap;
        address _pxt;
        address _pxrt;
        address _pxtStaking;
        address _pxtModusSwap;
        address _pxrtModusSwap;
        address _pxtStableCoinSwap;
        address _pxrtStableCoinSwap;
    }

    function modus() external returns (address);

    function modusAdmin() external returns (address);

    function kycAdmin() external returns (address);

    function proxyAdmin() external returns (address);

    function lostWalletAdmin() external returns (address);

    function setLostWalletAdmin(address) external;

    function modusFactory() external returns (address);

    function modusStaking() external returns (address);

    function priceModule() external returns (address);

    function kycModule() external returns (address);

    function modusTreasuryWallet() external returns (address);

    function projectStableCoin(uint256) external returns (address);

    function addStableCoin(address) external;

    function removeStableCoin(address) external;

    function isStableCoinSupported(address) external returns (bool);

    function isAccountBlackListed(address) external returns (bool);

    function blackListAccount(uint256, address) external;

    function whiteListAccount(address account) external;

    function blackListAccountByAdmin(address) external;

    function setStableCoin(uint256, address) external;

    function pxt() external returns (address);

    function stableCoinPXTSwap() external returns (address);

    function pxtStaking() external returns (address);

    function pxrt() external returns (address);

    function pxtModusSwap() external returns (address);

    function pxtStableCoinSwap() external returns (address);

    function pxrtModusSwap() external returns (address);

    function pxrtStableCoinSwap() external returns (address);

    function setKYCAdmin(address) external;

    function setBaseContracts(
        address,
        address,
        address,
        address,
        address
    ) external;

    function setModus(address) external;

    function setModusFactory(address) external;

    function setModusStaking(address) external;

    function setPriceModule(address) external;

    function setKycModule(address) external;

    function setImplementationContracts(
        address,
        address,
        address,
        address,
        address,
        address,
        address,
        address
    ) external;

    function setScheme(uint256, uint256) external returns (uint256);

    function setProjectDetails(
        uint256,
        uint256,
        bytes memory
    ) external returns (uint256);

    function setProjectDetails(
        uint256,
        uint256,
        bytes memory,
        bytes memory
    ) external returns (uint256);

    function getSchemeDetails(uint256)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getRewardPercentage(uint256, uint256) external returns (uint256);

    function getSchemesList() external returns (Scheme[] memory);

    function getProjectDetails(uint256) external returns (ModusProject memory);

    function getProjectList() external returns (ModusProject[] memory);

    function transferAdminOwnership(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IModusRegistry.sol";

contract Utility is Context {
    IModusRegistry modusRegistry;

    constructor(IModusRegistry _modusRegistry) {
        modusRegistry = _modusRegistry;
    }

    /// @notice Modifier to check whether the message.sender is Modus Admin
    modifier onlyModusAdmin() {
        require(
            _msgSender() == modusRegistry.modusAdmin(),
            "Utility: Not ModusAdmin"
        );
        _;
    }

    ///@notice sets the address of the Modus Registry
    ///@param _modusRegistry, address of the Modus Registry
    ///only accesible by modus admin
    function setModusRegistry(IModusRegistry _modusRegistry)
        external
        onlyModusAdmin
    {
        require(address(_modusRegistry) != address(0), "Utility: zero address");
        modusRegistry = _modusRegistry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModusRegistry.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/Singleton.sol";
import "../utils/ProxyUtility.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PXT is Singleton, ERC20Upgradeable, ProxyUtility {
    uint8 private _decimals;
    modifier onlyWhiteListedAddress(address receiver) {
        require(
            receiver ==
                modusRegistry.getProjectDetails(projectId)._pxtModusSwap ||
                receiver ==
                modusRegistry.getProjectDetails(projectId)._pxtStableCoinSwap,
            "PXT: Unauthorized 'To'address "
        );
        _;
    }

    constructor() initializer {}

    function initialize(
        uint256 _projectId,
        IModusRegistry _modusRegistry,
        uint8 equatedDecimal
    ) external initializer {
        modusRegistry = _modusRegistry;
        projectId = _projectId;
        string memory _name = string(
            abi.encodePacked("P(", Strings.toString(projectId), ")T")
        );
        string memory _symbol = string(
            abi.encodePacked("P(", Strings.toString(projectId), ")T")
        );
        _decimals = equatedDecimal;
        __ERC20_init(_name, _symbol);
        utilInitialize(_modusRegistry);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function upgradeSingleton(address _singleton) external onlyProxyAdmin {
        singleton = _singleton;
    }

    function mint(address account, uint256 tokens) external {
        require(
            msg.sender ==
                modusRegistry.getProjectDetails(projectId)._stableCoinPXTSwap,
            "PXT: Not a stableCoinPXTSwap"
        );
        _mint(account, tokens);
    }

    //function is created for testing purposes
    function mintForTesting(address account, uint256 tokens) public {
        _mint(account, tokens);
    }

    function transfer(address to, uint256 tokens)
        public
        override(ERC20Upgradeable)
        onlyWhiteListedAddress(to)
        returns (bool)
    {
        return super.transfer(to, tokens);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    )
        public
        override(ERC20Upgradeable)
        onlyWhiteListedAddress(to)
        returns (bool)
    {
        return super.transferFrom(from, to, tokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IStableCoinPXTSwap {
    function setPremiumInvestor(
        address,
        bool,
        uint256
    ) external;

    function setPremiumInvestorsList(
        address[] memory,
        bool[] memory,
        uint256[] memory
    ) external;

    function extendPremiumTimeFrame(uint256) external;

    function initiateSale() external;

    function toggleSale() external;

    function endSale() external;

    function swap(uint256) external;

    function tokenSale() external returns (bool);

    function upgradeSingleton(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPXT {
    function upgradeSingleton(address) external;

    function decimals() external returns (uint8);

    function mint(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPXTStaking {
    struct investmentDetails {
        uint256 stakedAmount;
        uint256 intialStakedDate;
        uint256 updatedStakedDate;
    }

    function investorDetails(address)
        external
        returns (investmentDetails memory);

    function projectStatus() external returns (bool);

    function beginEmission() external;

    function stake(address, uint256) external;

    function endProject() external;

     function cancelProject() external;

    function collectRemainingModusfromSwapContracts() external;

    function unstake(uint256) external;

    function adminUnstakeForLostwallet(
        address,
        address
    ) external;

    function upgradeSingleton(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITokenModusSwap {
    function upgradeSingleton(address) external;

    function setTokenAddress(address) external;

    function swap(address, uint256) external;

    function collectRemainingModus() external;

    function collectBackModus(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract Singleton {
    address internal singleton;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IModusRegistry.sol";

contract ProxyUtility is Initializable {
    IModusRegistry modusRegistry;
    uint256 projectId;

    /// @notice Event OwnershipTransferred is emitted when the ownership is transferred
    /// @param previousOwner and newOwner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function utilInitialize(IModusRegistry _modusRegistry)
        internal
        onlyInitializing
    {
        modusRegistry = _modusRegistry;
    }

    /// @notice Modifier to check whether the message.sender is Modus Admin
    modifier onlyModusAdmin() {
        require(
            msg.sender == modusRegistry.modusAdmin(),
            "ProxyUtility: Not ModusAdmin"
        );
        _;
    }

    /// @notice Modifier to check whether the message.sender is Modus Factory
    modifier onlyModusFactory() {
        require(
            msg.sender == modusRegistry.modusFactory(),
            "ProxyUtility: Not ModusFactory"
        );
        _;
    }

    modifier onlyModusAdminorModusFactory() {
        require(
            msg.sender == modusRegistry.modusAdmin() ||
                msg.sender == modusRegistry.modusFactory(),
            "ProxyUtility: Neither ModusAdmin or ModusFactory"
        );
        _;
    }

    ///@notice Modifier to check whether the caller in Proxy Admin
    modifier onlyProxyAdmin() {
        require(
            msg.sender == modusRegistry.proxyAdmin(),
            "ProxyUtility: Not ProxyAdmin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}