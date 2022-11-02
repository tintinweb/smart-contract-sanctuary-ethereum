// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";


contract TankFRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}

    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.TANK_F) {
            return '<rect transform="rotate(185 376.96 818.56)" x="376.96" y="818.56" width="206" height="192" fill="#EDEDED"/><rect transform="rotate(185 479.53 655.88)" x="479.53" y="655.88" width="45" height="433" fill="#EDEDED"/><rect transform="rotate(185 143.64 628.51)" x="143.64" y="628.51" width="45" height="433" fill="#EDEDED"/><rect transform="rotate(185 463.66 619.36)" x="463.66" y="619.36" width="327" height="30" fill="#EDEDED"/><rect transform="rotate(185 487.73 298.24)" x="487.73" y="298.24" width="327" height="30" fill="#EDEDED"/><rect transform="rotate(185 421.11 807.37)" x="421.11" y="807.37" width="43" height="191" fill="#F3F3F1"/><rect transform="rotate(185 170.63 790.48)" x="170.63" y="790.48" width="43" height="198" fill="#F3F3F1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 443.9 53.487)" width="206" height="192" fill="#EDEDED"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 485.43 72.178)" width="43" height="191" fill="#F3F3F1"/><rect transform="matrix(-.9962 -.087156 -.087156 .9962 235.82 45.32)" width="43" height="198" fill="#F3F3F1"/><rect transform="rotate(185 420.85 810.36)" x="420.85" y="810.36" width="49" height="189" fill="#EDEDED"/><rect transform="rotate(185 178.77 789.18)" x="178.77" y="789.18" width="49" height="189" fill="#EDEDED"/><rect transform="rotate(185 469.3 256.47)" x="469.3" y="256.47" width="49" height="189" fill="#EDEDED"/><rect transform="rotate(185 227.23 235.3)" x="227.23" y="235.3" width="49" height="189" fill="#EDEDED"/><rect transform="rotate(185 108.22 436.69)" x="108.22" y="436.69" width="27" height="64" fill="#EDEDED"/><rect transform="rotate(185 76.955 426.93)" x="76.955" y="426.93" width="21" height="44" fill="#1C55B4"/><line x1="108.05" x2="82.148" y1="438.68" y2="436.42" stroke="#000" stroke-width="28"/><line x1="114.06" x2="88.162" y1="369.94" y2="367.68" stroke="#000" stroke-width="28"/><line x1="91.934" x2="73.747" y1="441.58" y2="418.73" stroke="#000" stroke-width="28"/><line transform="matrix(-.74912 .66244 .66244 .74912 107.96 374.91)" x2="29.206" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="81.849" x2="86.381" y1="428.36" y2="376.56" stroke="#000" stroke-width="18"/><path d="m83.607 362.37c-0.9807-0.158-1.9741-0.281-2.9792-0.369-22.558-1.974-42.444 14.713-44.417 37.27-1.9735 22.558 14.713 42.444 37.271 44.418 1.0051 0.088 2.0049 0.139 2.998 0.154l2.4613-28.133c-0.9792 0.143-1.9903 0.175-3.0189 0.085-7.1524-0.625-12.443-6.931-11.818-14.083 0.6257-7.153 6.9312-12.444 14.084-11.818 1.0286 0.09 2.0187 0.298 2.9582 0.608l2.4613-28.132z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="477.02" x2="515.27" y1="661.69" y2="224.36" stroke="#000" stroke-width="28"/><line x1="521.85" x2="427.58" y1="237.48" y2="179.04" stroke="#000" stroke-width="28"/><line transform="matrix(-.92851 .3713 .3713 .92851 490.96 662.91)" x2="110.91" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.087182 -.99619 -.99619 -.087182 85.512 627.44)" x2="439" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.92851 -.3713 -.3713 -.92851 123.77 190.11)" x2="110.91" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="92.889" x2="187.15" y1="615.54" y2="673.98" stroke="#000" stroke-width="28"/><rect transform="rotate(185 440.54 585.22)" x="440.54" y="585.22" width="292" height="291" fill="#F8F8F8" stroke="#000" stroke-width="28"/><line transform="matrix(.9962 .087156 .087156 -.9962 377.12 679.05)" x2="71" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 445.68 710.14)" x2="104" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.93485 .35504 .35504 .93485 436.61 813.74)" x2="66.641" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="193.6" x2="122.87" y1="677.04" y2="670.86" stroke="#000" stroke-width="28"/><line x1="135.86" x2="126.79" y1="683.04" y2="786.64" stroke="#000" stroke-width="28"/><line x1="120.02" x2="177.26" y1="773.39" y2="807.51" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 452.83 605.37)" x2="63" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 160.95 579.83)" x2="63" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.99647 -.083993 -.083993 .99647 450.48 632.26)" x2="320" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="189.3" x2="173.88" y1="600.18" y2="810.64" stroke="#000" stroke-width="28"/><line transform="matrix(-.10122 .99486 .99486 .10122 408.43 619.55)" x2="211.02" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 371.05 782.91)" x2="198" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 375.36 745.15)" x2="198" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="421.14" x2="491.87" y1="175.97" y2="182.16" stroke="#000" stroke-width="28"/><line x1="478.88" x2="487.94" y1="169.98" y2="66.375" stroke="#000" stroke-width="28"/><line x1="494.72" x2="437.48" y1="79.622" y2="45.503" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 237.61 173.97)" x2="71" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.087156 -.9962 -.9962 -.087156 169.06 142.87)" x2="104" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.93485 -.35504 -.35504 -.93485 178.13 39.27)" x2="66.641" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="467.74" x2="473.23" y1="274.41" y2="211.65" stroke="#000" stroke-width="28"/><line x1="175.85" x2="181.34" y1="248.87" y2="186.11" stroke="#000" stroke-width="28"/><line x1="482.77" x2="164.08" y1="262.67" y2="233.77" stroke="#000" stroke-width="28"/><line transform="matrix(.10122 -.99486 -.99486 -.10122 207.32 233.55)" x2="211.02" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="426.45" x2="441.87" y1="252.92" y2="42.466" stroke="#000" stroke-width="28"/><line x1="430.75" x2="233.5" y1="100.52" y2="83.263" stroke="#000" stroke-width="28"/><line x1="428.43" x2="231.19" y1="138.46" y2="121.21" stroke="#000" stroke-width="28"/><line x1="375.54" x2="171.31" y1="823.46" y2="805.59" stroke="#000" stroke-width="28"/><line x1="443.43" x2="239.2" y1="47.423" y2="29.556" stroke="#000" stroke-width="28"/><path d="m310.47 518.53 14.244 36.482-12.222-1.069-14.244-36.482 12.222 1.069zm-1.988-5.09v-1e-3l-2e-3 1e-3h2e-3z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="327.78" x2="311.78" y1="554.64" y2="553.24" stroke="#000000" stroke-width="2"/><line x1="330.7" x2="323.12" y1="521.3" y2="520.64" stroke="#000000" stroke-width="2"/><line transform="matrix(-.70132 .71285 -.73612 -.67685 327.42 520.01)" x2="43.555" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line x1="302.37" x2="268.11" y1="551.95" y2="548.95" stroke="#000000" stroke-width="2"/><line x1="313.86" x2="270.92" y1="519.83" y2="516.07" stroke="#000000" stroke-width="2"/><line x1="288.71" x2="291.49" y1="550.22" y2="518.51" stroke="#000000" stroke-width="11"/><line x1="274.4" x2="277.18" y1="548.97" y2="517.25" stroke="#000000" stroke-width="11"/><path d="m254.65 514.75-22.371 29.161-12.507-1.094-0.328-0.23 22.226-28.973 12.98 1.136z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="236.25" x2="216.32" y1="545.26" y2="543.52" stroke="#000000" stroke-width="2"/><line x1="257.97" x2="238.04" y1="515.04" y2="513.3" stroke="#000000" stroke-width="2"/><path d="m179.3 474.82 35.245-14.284 3e-3 8e-3 -1.074 12.279-33.817 13.705-1.163-2.489 0.806-9.219zm-4.298 1.742v1e-3 -1e-3z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m178.06 489 35.244-14.283 4e-3 7e-3 -1.07 12.227 0.104 9e-3 -33.926 13.749-1.163-2.49 0.807-9.219zm-4.299 1.742v1e-3 -1e-3z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="177.45" x2="180.67" y1="505.99" y2="469.13" stroke="#000000" stroke-width="2"/><line x1="211.89" x2="215.12" y1="490.93" y2="454.07" stroke="#000000" stroke-width="2"/><line x1="217.02" x2="182.98" y1="434.23" y2="431.25" stroke="#000000" stroke-width="11"/><line x1="218.2" x2="184.17" y1="420.69" y2="417.72" stroke="#000000" stroke-width="11"/><line x1="219.46" x2="185.42" y1="406.32" y2="403.34" stroke="#000000" stroke-width="11"/><line x1="216.22" x2="220" y1="441.42" y2="398.28" stroke="#000000" stroke-width="2"/><line x1="183.02" x2="186.79" y1="438.51" y2="395.38" stroke="#000000" stroke-width="2"/><path d="m189.71 354.31 31.404 23.467-1.053 12.038-0.401 0.592-31.077-23.222 1.127-12.874v-1e-3z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m191.11 338.34 31.405 23.466-1.053 12.038-0.401 0.592-31.077-23.221 1.126-12.875z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m192.49 322.58 31.405 23.466-1.053 12.038-0.401 0.593-31.077-23.222 1.126-12.875z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m194.62 307.76 31.405 23.466-1.053 12.038-0.401 0.592-31.077-23.222 1.126-12.873v-1e-3z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line transform="matrix(.099952 -.99499 .99486 .1013 220.68 392.32)" x2="65.064" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line transform="matrix(.099907 -.995 .99485 .10135 189.32 368.4)" x2="65.064" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><path d="m243.83 295.55 20.571 21.927-1.184 13.309 0.036 3e-3 -0.795 0.596-33.528-35.739 1.674-1.253 13.226 1.157z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line transform="matrix(.063923 -.99796 .9978 .066358 263.95 331.86)" x2="34.071" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line x1="267.93" x2="261.31" y1="297.93" y2="297.35" stroke="#000000" stroke-width="2"/><line x1="248.09" x2="228.07" y1="296.19" y2="294.59" stroke="#000000" stroke-width="2"/><path d="m362.03 330.28 2.12-24.233-10.959-0.959-3.042 34.772 0.056 4e-3 11.825-9.584z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="367.74" x2="351.16" y1="307.37" y2="305.92" stroke="#000000" stroke-width="2"/><line transform="matrix(.78752 -.61629 .74293 .66936 355.35 335.68)" x2="14.788" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><path d="m404.66 310.37-25.437 29.73-10.169-0.889-2.207-1.365 24.926-29.133-0.046 0.526 12.933 1.131z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m422.14 311.9-25.437 29.73-10.169-0.89-2.208-1.364 24.928-29.134-0.046 0.526 12.932 1.132z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="424.89" x2="387.1" y1="312.37" y2="309.06" stroke="#000000" stroke-width="2"/><line x1="424.89" x2="387.1" y1="312.37" y2="309.06" stroke="#000000" stroke-width="2"/><line x1="399.07" x2="364.05" y1="342.06" y2="339" stroke="#000000" stroke-width="2"/><line x1="399.07" x2="364.05" y1="342.06" y2="339" stroke="#000000" stroke-width="2"/><path d="m366.44 324 2.564-2.268-1.603-1.287 15.913-13.693 3.859 3.18-18.494 15.913-2.239-1.845z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m441.35 331.96-18.039 14.178-19.165 1.084 37.859-29.756-1.264 14.44 0.609 0.054zm9.264-7.282 1.252-0.984-1.058-1.235-0.194 2.219z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="439.68" x2="441.42" y1="332.62" y2="312.64" stroke="#000000" stroke-width="2"/><path d="m402.65 373.68 0.94-10.749 35.371-15.634-1.094 12.502-34.711 15.343-0.72-1.481 0.214 0.019z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m401.4 387.88 0.94-10.749 35.371-15.635-1.078 12.323 0.327 0.028-35.054 15.495-0.72-1.481 0.214 0.019z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m400.14 402.26 0.94-10.749 35.372-15.635-1.094 12.502-34.712 15.344-0.72-1.481 0.214 0.019z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="399.92" x2="404.45" y1="407" y2="355.26" stroke="#000000" stroke-width="2"/><line transform="matrix(.089435 -.99599 .996 .089345 435.33 392.39)" x2="52.7" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line transform="matrix(.99881 -.04884 .060603 .99816 409.19 346.87)" x2="29.563" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line x1="432.53" x2="398.72" y1="423.65" y2="420.69" stroke="#000000" stroke-width="11"/><path d="m395.56 456.81 38.411-15.186-2.152-0.188 0.977-11.174-36.164 14.297-1.072 12.251z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="430.61" x2="433.07" y1="443.84" y2="415.67" stroke="#000000" stroke-width="2"/><line x1="397.6" x2="399.27" y1="431.76" y2="412.71" stroke="#000000" stroke-width="2"/><line x1="429.16" x2="429.74" y1="460.4" y2="453.78" stroke="#000000" stroke-width="2"/><line x1="395.36" x2="396.73" y1="457.44" y2="441.7" stroke="#000000" stroke-width="2"/><line transform="matrix(-.73012 -.68332 .69739 -.71669 430.44 457.18)" x2="43.122" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><path d="m391.85 493.93 33.353 0.921-0.8 9.137 3.036 0.266-0.037 1.662-36.512-1.008 0.96-10.978zm-3.493 10.8-2e-3 0.108 1.804 0.05-1.802-0.158z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="423.27" x2="424.42" y1="505.44" y2="492.3" stroke="#000000" stroke-width="2"/><line x1="390.7" x2="391.85" y1="504.93" y2="491.78" stroke="#000000" stroke-width="2"/><line x1="421.45" x2="422.19" y1="526.33" y2="517.82" stroke="#000000" stroke-width="2"/><line x1="393" x2="393.68" y1="478.64" y2="470.9" stroke="#000000" stroke-width="2"/><line transform="matrix(-.50527 -.86296 .88342 -.46859 422.78 522.55)" x2="56.164" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><path d="m366.46 524.7 33.627 35.657-16.369-1.432-33.462-35.481 1.153-0.859-0.07 0.792 15.121 1.323zm24.805 42.228-0.165-0.176 0.358 0.032-0.193 0.144z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><path d="m346.69 521.8 19.229 35.573-13.057-1.142-19.229-35.573 13.057 1.142z" clip-rule="evenodd" fill="#000000" fill-rule="evenodd"/><line x1="404.52" x2="382.28" y1="560.95" y2="559" stroke="#000000" stroke-width="2"/><line x1="372.5" x2="350.26" y1="558.15" y2="556.2" stroke="#000000" stroke-width="2"/><line x1="370.07" x2="332.72" y1="524.42" y2="521.16" stroke="#000000" stroke-width="2"/><line x1="386.97" x2="379.86" y1="525.9" y2="525.28" stroke="#000000" stroke-width="2"/><line transform="matrix(.40946 -.91233 .93724 .34867 369.85 557.71)" x2="35.345" y1="-1" y2="-1" stroke="#000000" stroke-width="2"/><line x1="328.21" x2="331.17" y1="337.48" y2="303.61" stroke="#000" stroke-width="11"/><line x1="337.76" x2="319.83" y1="337.32" y2="335.75" stroke="#000" stroke-width="2"/><line x1="339.55" x2="320.62" y1="305.35" y2="303.7" stroke="#000" stroke-width="2"/><path d="m315.48 323.1-6.361-21.418-11.781-1.031 10.587 35.649 7.555-13.2z" clip-rule="evenodd" fill="#000" fill-rule="evenodd"/><line x1="313.92" x2="323.63" y1="323.82" y2="304.59" stroke="#000" stroke-width="2"/><line x1="311.66" x2="295.07" y1="302.91" y2="301.46" stroke="#000000" stroke-width="2"/>';
        } else {
            revert IWatchScratchersWatchCaseRenderer.WrongCaseRendererCalled();
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchScratchersWatchCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
}