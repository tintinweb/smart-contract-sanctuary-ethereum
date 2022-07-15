// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library LgSVG {

    /**
    * @notice render an eyes asset
    * @param lgAssetId the large asset id of the eyes item
    * @return string of svg
    */
    function _eyes(uint256 lgAssetId)
        internal
        pure
        returns (string memory)
    {
        string[8] memory EYES = [
            // 0 normal male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h6v1h1v2h-9v-1h1v-1h1zM38,24h4v3h-5v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h6v1h-3v1h2v-1h2v2h-1v1h1v1h-1v1h-2v-1h-3v1h-1v-1h-2v-1h1v-1h-1v-1h1v-1h1zM38,24h4v1h-3v1h2v-1h1v5h-1v-1h-3v1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h6v1h-6v1h6v-1h1v2h-9v-1h1v-1h1zM38,24h4v1h-4v1h4v1h-5v-2h1zM29,28h3v1h1v1h-1v-1h-3v1h-1v-1h1zM38,28h3v1h1v1h-1v-1h-3v1h-1v-1h1z\' fill=\'var(--dmb5)\'/%253E',
            // 1 angry male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h1v2h-4v-1h-5v-1h1v-1h1zM40,24h2v3h-2v1h-3v-2h1v-1h2z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h-3v1h2v-1h2v3h-1v1h-1v-1h-3v1h-1v-1h-2v-1h1v-1h-2v-1h1v-1h1zM40,24h2v6h-1v-1h-3v1h-1v-4h1v-1h2v1h-1v1h1v-1h1v-1h-1v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h3v1h3v1h1v2h-3v1h1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-5v-1h1v-1h1v1h3v1h3v-1h-3v-1h-3zM40,24h2v1h-2v1h-2v1h2v-1h2v1h-2v1h1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h-1v-2h1v-1h2z\' fill=\'var(--dmb5)\'/%253E',
            // 2 sad male
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-4v1h-5v-1h1v-1h1v-1h3zM38,24h2v1h2v3h-2v-1h-3v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-1v1h1v1h-1v1h-2v-1h-3v1h-1v-1h-2v-2h1v-1h1v-1h3v1h2v-1h-2zM38,24h2v1h-1v1h1v1h1v-1h-1v-1h1v-1h1v6h-1v-1h-3v1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,24h3v1h1v2h-4v1h1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h-3v-1h1v-1h1v-1h3v1h-3v1h3v-1h3v-1h-3zM38,24h2v1h2v1h-2v1h2v1h-1v1h1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-3v-2h1v1h2v-1h-2z\' fill=\'var(--dmb5)\'/%253E',
            // 3 surprised male
            '%253Cpath d=\'M29,28h3v2h-3zM38,28h3v2h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M28,24h6v1h1v2h-9v-1h1v-1h1zM38,24h4v3h-5v-2h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h6v1h-3v1h2v-1h2v2h-1v1h1v1h-1v1h-2v1h-3v-1h3v-1h-3v1h-1v-1h-2v-1h1v-1h-1v-1h1v-1h1zM38,24h4v1h-3v1h2v-1h1v5h-1v-1h-3v1h3v1h-3v-1h-1v-2h1v-1h-1v-2h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M28,24h6v1h-6v1h6v-1h1v2h-3v1h-3v-1h-3v-1h1v-1h1zM38,24h4v1h-4v1h4v1h-1v1h-3v-1h-1v-2h1zM28,29h1v1h-1zM32,29h1v1h-1zM37,29h1v1h-1zM41,29h1v1h-1z\' fill=\'var(--dmb5)\'/%253E',
            // 4 normal female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,25h4v1h1v1h-6v-1h1zM38,25h3v1h1v1h-5v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h3v1h2v-1h1v1h1v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM37,25h2v1h2v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,26h8v1h-8zM37,26h5v1h-5zM29,28h5v1h-1v1h-1v-1h-3v1h-1v-1h1zM38,28h4v2h-1v-1h-3v1h-1v-1h1z\' fill=\'var(--dmb5)\'/%253E',
            // 5 angry female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,25h2v1h2v1h1v1h-3v-1h-3v-1h1zM40,25h1v1h1v1h-2v1h-3v-1h1v-1h2z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h4v1h3v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM39,25h1v1h1v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1v-1h2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,26h4v1h4v1h-1v1h-1v1h-1v-1h-3v1h-1v-1h1v-1h2v-1h-4zM40,26h2v1h-2v1h2v2h-1v-1h-3v1h-1v-1h1v-1h-1v-1h3z\' fill=\'var(--dmb5)\'/%253E',
            // 6 sad female
            '%253Cpath d=\'M29,29h3v1h-3zM38,29h3v1h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M31,25h2v1h1v1h-3v1h-3v-1h1v-1h2zM38,25h2v1h1v1h1v1h-2v-1h-3v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,25h3v1h2v-1h1v1h1v1h-1v1h1v2h-3v-1h-3v1h-2v-1h-1v-1h1v-2h1zM37,25h2v1h2v-1h1v5h-1v-1h-3v1h-2v-1h1v-1h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,26h4v1h-3v1h2v1h-1v1h-1v-1h-3v1h-1v-1h1v-1h-2v-1h4zM37,26h3v1h2v3h-1v-1h-3v1h-1v-1h1v-1h1v-1h-2z\' fill=\'var(--dmb5)\'/%253E',
            // 7 surprised female
            '%253Cpath d=\'M29,28h3v2h-3zM38,28h3v2h-3z\' fill=\'var(--dme)\'/%253E%253Cpath d=\'M30,29zh1v1h-1zM39,29h1v1h-1z\' fill=\'var(--dmi)\'/%253E%253Cpath d=\'M29,24h4v1h1v1h-6v-1h1zM38,24h3v1h1v1h-5v-1h1z\' fill=\'var(--dmh)\'/%253E%253Cpath d=\'M28,24h3v1h2v-1h1v1h1v1h-1v1h1v3h-3v-1h-3v1h-2v-1h-1v-2h1v-2h1zM37,24h2v1h2v-1h1v6h-1v-1h-3v1h-2v-1h1v-2h1v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M27,25h8v1h-8zM37,25h5v1h-5zM29,27h5v1h-1v2h-1v-2h-3v2h-1v-2h1zM38,27h4v3h-1v-2h-3v2h-1v-2h1z\' fill=\'var(--dmb5)\'/%253E'
        ];
        return EYES[lgAssetId];
    }

    /**
    * @notice render a mouth asset
    * @param lgAssetId the large asset id of the mouth item
    * @return string of svg
    */
    function _mouth(uint256 lgAssetId)
        internal
        pure
        returns (string memory)
    {
        string[16] memory MOUTHS = [
            // 0 toothy smile male
            '%253Cpath d=\'M33,40h5v1h-5z\' fill=\'white\'/%253E%253Cpath d=\'M32,40h2v1h-2zM38,41h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,40h1v1h5v-1h1v1h-1v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 1 small smile male
            '%253Cpath d=\'M34,40h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h5v1h-5v-1h-1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 2 large smile male
            '%253Cpath d=\'M33,40h5v1h-5z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,39h1v1h7v-1h1v1h-1v1h-7v-1h-1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 3 frown male
            '%253Cpath d=\'M34,40h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h1v1h-1v-1h-6v1h-1v-1h1zM35,42h2v1h-2z\' fill=\'var(--dmb35)\'/%253E',
            // 4 stoic male
            '%253Cpath d=\'M34,40h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h-6zM35,42h3v1h-3z\' fill=\'var(--dmb35)\'/%253E',
            // 5 sewn male
            '%253Cpath d=\'M31,38h1v1h-1zM36,39h1v1h1v-1h1v2h-1v1h-3v-1h-1v-1h2zM32,40h1v2h-1zM37,43h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h2v-1h1v1h1v-1h1v1h2v1h-1v1h-1v-1h-1v2h-1v-2h-1v1h-1v-1h-3v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 6 small smile fangs male
            '%253Cpath d=\'M34,41h1v2h-1zM38,41h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M32,40h1v1h1v-1h4v1h1v1h-6v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,39h1v1h6v1h-6v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 7 stoic fangs male
            '%253Cpath d=\'M34,41h1v2h-1zM38,41h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M34,40h4v1h1v1h-6v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M33,40h6v1h-6z\' fill=\'var(--dmb35)\'/%253E',
            // 8 toothy smile female
            '%253Cpath d=\'M32,40h5v1h-5z\' fill=\'white\'/%253E%253Cpath d=\'M31,40h2v1h-2z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,40h1v1h5v-1h1v1h-1v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 9 small smile female
            '%253Cpath d=\'M33,41h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,40h1v1h5v1h-5v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 10 large smile female
            '%253Cpath d=\'M32,41h5v1h-5z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M30,40h1v1h7v-1h1v1h-1v1h-7v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 11 frown female
            '%253Cpath d=\'M33,40h3v1h-3z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M32,40h4v1h1v1h-1v-1h-4v1h-1v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 12 stoic female
            '%253Cpath d=\'M32,41h4v1h-4z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,41h6v1h-6z\' fill=\'var(--dmb35)\'/%253E',
            // 13 sewn female
            '%253Cpath d=\'M30,38h1v1h-1zM35,39h1v1h1v-1h1v2h-1v1h-3v-1h-1v-1h2zM31,40h1v2h-1zM36,43h1v1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,39h1v1h2v-1h1v1h1v-1h1v1h2v1h-1v1h-1v-1h-1v2h-1v-2h-1v1h-1v-1h-3v-1h1z\' fill=\'var(--dmb35)\'/%253E',
            // 14 small smile fangs female
            '%253Cpath d=\'M32,42h1v2h-1zM36,42h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M30,41h1v1h1v-1h4v1h1v1h-6v-1h-1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M30,40h1v1h6v1h-6v-1h-1z\' fill=\'var(--dmb35)\'/%253E',
            // 15 stoic fangs female
            '%253Cpath d=\'M32,42h1v2h-1zM36,42h1v2h-1z\' fill=\'white\'/%253E%253Cpath d=\'M32,41h4v1h1v1h-6v-1h1z\' fill=\'var(--dmb15)\'/%253E%253Cpath d=\'M31,41h6v1h-6z\' fill=\'var(--dmb35)\'/%253E'
        ];
        return MOUTHS[lgAssetId];
    }

    /**
    * @notice render the miner base
    * @param classId class id (0 == warrior, 1 == mage, 2 == ranger, 3 == assassin)
    * @param genderId gender id (0 == male, 2 == female)
    * @return string of svg
    */
    function renderBase(uint256 genderId, uint256 classId, uint256 eyesId, uint256 mouthId)
        external
        pure
        returns (string memory)
    {
        string[2] memory MINERS = [
            // 0 base male
            '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h2v-1h2v-1h1v-7h-1v-1h-1v-1h-1v-1h-1v-13h1v-3h1v-1h1v-1h1v-1h1v-1h2v-1h1v-1h3v-1h7v1h3v1h2v1h1v1h1v1h1v2h1v3h1v17h-1v5h-1v3h-1v1h-1v1h2v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'var(--dms)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAApNJREFUeNrsm12OwiAQx0vjRfaF03gVXjyBJ9gXrtLT8LJHca0BM5JhGGCgVtukibak8uM/zFejut1u06cf8/QFxwF5QB6QB+QBeUAekF8OqQb+liXumT1D2gpIsycrWaG0PzlHGGszC/I2cLYALgVsP0W93YFCQC30TBHQWdhEw+GEnus+WUFRNU89qENLRSnFHovGNyUT4bpAhsmtAKmJjoDrZao6B7JeKzklTFZaSYdBQWUolSjl3zZBz004Uosa495uT5Y6maAg3MuSx2n0JqYcEdest4I0qQoiVoerUjxuS49rC8qpnvVod8djSjKd0hAisT9nQXPV3II3OJlggv7zBbn2OFtBJRP0HKDG9hb4vtzPS2bM5kq+wCCAuVjnMs/YFJJjpo65X3+5+e0WSurSJBx7BjDLs6Sas4CZmsj5nDvVlNspeVfLIGGktIDWkXqr2Z7vyooU4pJpxOph/7yXhIvgMt4xAC7IPXj9sZg1lYpk7mqwrMSrQTkg50EwM1/8/SY1RybojmiTOERJB+6bqaGzPhLyGSsTPSCHeePIEqoSg+FvtTDAVI7qU7rmtuRoSA0m/zxhnorktXpvkI9JQzUxRaU7A70hzylQAKfjFkh07xk6ahdhFtxn2Cu3hYCFgV4jDkUsrZPwrtZPkKpEYBxcClI3kRSxJeOxqb4OMD/OxBfC1H+CqXIbYlKQL3CpNAs4F12zbwPgSCVtokAmX+5EC1CzxwxlLa2Qlqj8yZoxhkWU5sI67tYohUw+jOu2GZA5h+OYFsWGVtyVaoGUaEZR0L6mTc5FTbxOWzUkU83WxbBxIf/yyqE0sa6BpBLzltBQG95IyJZuN2dsh382XDdXctDevapv+F/IvwADAGp6okFeqr7oAAAAAElFTkSuQmCC\'/%253E',
            // 1 base female
            '%253Cpath d=\'M0,57v-5h1v-1h2v-1h2v-1h4v-1h3v-1h2v-1h3v-1h2v-8h-1v-1h-1v-1h-1v-1h-1v-13h1v-3h1v-1h1v-1h1v-1h1v-1h2v-1h1v-1h3v-1h7v1h3v1h2v1h1v1h1v1h1v2h1v3h1v17h-1v2h-1v1h-1v2h-1v2h-1v1h-1v2h4v1h2v1h4v1h2v1h4v1h2v1h1v1h1v2z\' fill=\'var(--dms)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAodJREFUeNrsm+1twyAQho2VRfqHBbJGFugQ7JAdGCILeI0uwDKuqUC6UA4OOIidGMlSZdOYh/c+iSLWdZ3efczTB4wT8oQ8IU/IE/KEPCE/HFIMfJdOPFNHhtQVkOpIVmKhpLsow8/VmQ3ZDZwugMOA9buodzhQCCiZPpMFdGY2UT8M0+ead1aQVc1LD2p/pCKEIM+N5jfBk+G6QPrFWQBsoSPgepmqzIHYeyUXh8lyK2liUFCZlEop5XdboOcWHKiVmmN255OlQcYrCH2Zc1xGO3EqEFHN+lWQCusgQnWoKoXzXhlxdUE71bMf7R54VEmlU5pCOPxzZjRXSW14fZDxJhjzRTinFZSzQFc1pV4KlMsfZ+bAM8VMt1eSHwmZNVMq4DZPQtPkypdcSsrSIhwZ1z0qqYIcaWFvNb0l8FlJ3cRhSm6LU1gaQRacUvxh1eQu65ohnb95UKviUqICrFsd3GP7+7umyR5Ru6pEVSKx8xq3Sfb5FQSon+DZsQp0xA9NphdVU8PJes9+8oaZrS/XYNVDNcuafNsTcomARisfrF51getPxZZgNPqrO+kBIRCsU8ElW810FGRWTUxRDjMdqeQTqFUo5ouBok8qtrZfLJCRFxsE9Iblzp4FvOAA3BaoQctlwH2JRN0lsSH/VIz1lCWb0gKpYWnngEwkx8lEelky9TCaTnpDauzQKpMqJCGX2vHl6mE2ExalqpWE9EizTCnRFPFeM6SmviTnKzWg9sQ8+B/dAiuopkgN2wRIDNQUWhQZWlB3qgWyY4rQoKdF1yIoJ20tkNSDrMbN0GEj/3T6V9oW1UCmCvNORUGdD7eedlPmdvhlw/3lSg7y3bv4hN+F/AowAGIWzHdTKpamAAAAAElFTkSuQmCC\'/%253E'
        ];

        return string(abi.encodePacked(
            (genderId == 0 && classId == 1 ? '%253Cdefs%253E%253Cmask id=\'mhm\'%253E%253Cpath d=\'M0,0h57v57h-57z\' fill=\'white\'/%253E%253Cpath d=\'M31,37h10v19h-10z\' fill=\'black\'/%253E%253C/mask%253E%253C/defs%253E' : ''),
            MINERS[genderId],
            _eyes((genderId * 4) + eyesId),
            _mouth((genderId * 8) + mouthId)
        ));
    }

    /**
    * @notice render the miner mods
    * @param modId class id (0-3 male, 4-7 female)
    * @return string of svg
    */
    function renderMod(uint256 modId)
        external
        pure
        returns (string memory)
    {
        string[8] memory CLASS_MODS = [
            // 0 warrior male
            '',
            // 1 mage male
            '%253Cpath d=\'M20,33h1v1h1v1h2v1h1v1h2v1h2v1h2v-1h9v1h1v-1h1v-1h1v7h-1v4h-1v2h-1v2h-1v2h-1v1h-1v1h-2v-1h-2v-1h-2v-1h-1v-1h-1v-2h-1v-1h-2v-1h-2v-1h-1v-1h-1v-1h-1v-1h-1v-1h-1v-7h1z\' fill=\'var(--dmh)\'/%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAdJJREFUeNrsm0GOgyAYhaWZ03gEViacwj3XmNVcw72nIJlVjzDX6UDy0/zzQm0TsTDtIyHWSg2f7/GgRs3lchlevZyGNyiEJCQhCUlIQhKSkIQkJCEJSUhCEpKQhCQkIQlJSEISkpCEJCQhXxPSGPMV6xTrWyjZDeiRkN+ibHPYU2WrznETCrBNQWsr6fWOeuhit6rxd6EnuzoFNcPTJX9gU8dF/aIr5Pi0u0epE7WqWHXKli0c1yUUjk9SB7UNt9o/Wj8OUjKVpNAqal63ynpOVErtLZzjUyu/txwBmTp8VkHkkzURNF3huJ8Blxvje1YXrCvIs1LmRwA8Bk5aNCjAVadyvABJ5QTp5XNXkE46i6CYA06l5Srj0ZXa5TaY3D2k69WysYxbY3fj2b4F5l7XDaRSxYKFvep0brfAQkKfZ/0Py7pSag5bUPq7PZP/oZDZesqCGdRq6+bURTBU+47d2ysJoE5NL7nTS1arkJ46Ve2e8Xj4n2YIFaeUHVW4eEjdqiq2ujOAoDgeq6r4FEhct4K644Ztxw1X9KkkwJaSd4Rgsg/Mpf3eyIK51MvYtCUVa7wIYFq9TQBr2VAIIlcL1LR8ZaJwlyDUBmwO+azyK8AAkbk+yZJBIeYAAAAASUVORK5CYII=\'/%253E',
            // 2 ranger male
            '%253Cpath d=\'M34,29h2v2h2v2h1v2h1v3h-2v1h-5v-1h-2v-3h1v-2h1v-1h1z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M36,30h1v2h1v4h1v3h-4v-1h-1v-1h1v1h3v-2h-1v-4h-1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M36,29h1v1h-1zM37,33h1v2h1v1h-1v-1h-1zM32,36h1v1h1v1h1v1h-1v-1h-1v-1h-1zM37,37h2v1h-1v1h-2v-1h1z\' fill=\'var(--dmb15)\'/%253E',
            // 3 assassin male
            '%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADkAAAA5CAYAAACMGIOFAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAARhJREFUeNrs2oENgyAQQFFwIkdgJEZxJEfoRjQaSK5U1MqRUP0k5GxSlZc7j5hoQwjm7mMwDxggQYIECRIkSJAgQYIECRIkSJAgQYIECRIkSJAgQYK8H9Jau0wXo9rsNZPuCeU6R6i7I9KJOPeS1aFBBseUyRDCCo0fXyy/za9TZVy58cGCXAIdxbPXrF5XA6TXhF6tADlbNJ5XLNl1O1lKditm287Hsca20bq7jkdQAXTimf2qCvnfqv1b84sskQGfZXa3WW2tQQJTA+sNmUNlGct4qmPXrrElcgu8Bx0L2a9Gqj+ThQVNGaQUmwz1TMrrFTLrz3bp2KhMd+VaaCJ7p/lCRUzpvK6QvDSDBAkSJEiQ/zfeAgwAaFfCwD9utk4AAAAASUVORK5CYII=\'/%253E',
            // 4 warrior female
            '',
            // 5 mage female
            '%253Cstyle%253E:root{--dme:var(--dm31)}%253C/style%253E',
            // 6 ranger female
            '%253Cpath d=\'M34,29h2v2h2v2h1v2h1v3h-2v1h-5v-1h-2v-3h1v-2h1v-1h1z\' fill=\'var(--dms)\'/%253E%253Cpath d=\'M35,30h1v2h1v4h1v3h-4v-1h-1v-1h1v1h3v-2h-1v-4h-1z\' fill=\'var(--dmb35)\'/%253E%253Cpath d=\'M35,29h1v1h-1zM36,33h1v2h1v1h-1v-1h-1zM31,36h1v1h1v1h1v1h-1v-1h-1v-1h-1zM36,37h2v1h-1v1h-2v-1h1z\' fill=\'var(--dmb15)\'/%253E',
            // 7 assassin female
            '%253Cpath d=\'M27,29h1v1h-1v1h1v1h-1v-1h-2v1h-2v-1h2v-1h2zM32,30h1v1h1v1h-1v-1h-1zM41,31h1v1h-1v1h-1v1h-1v-1h1v-1h1zM23,35h1v1h1v1h2v-1h1v1h-1v1h1v1h1v1h1v1h-1v-1h-1v-1h-1v-1h-2v1h-1v-1h1v-1h-1v-1h-1zM35,44h1v1h-1v1h-2v1h-1v-1h1v-1h2z\' fill=\'var(--dmb2)\'/%253E'
        ];
        return CLASS_MODS[modId];
    }

    /**
    * @notice return a background image
    * @param bgType background type
    * @return string of base64-encoded image
    */
    function _background(uint256 bgType)
        internal
        pure
        returns (string memory)
    {
        string[3] memory backgrounds = [
            // 0 Dungeon
            'R0lGODlhOQA5AJEAABsbGwcHBxAQEAAAACH5BAAAAAAALAAAAAA5ADkAAAL/VCIAhid/onSqsrScg1OaB34b01HV8oUiwpUNB12wFSVqujXsRWtwGkKcMjsPK3cTni6jmiqgeB6dzREIirq6nJzsdNdyBaHX8Hai1Z3XVTVriPKQfun3MNzKw5fU4o23F9VX9hciOEX4VAhySFckpmBFCPbVgSEZU8clozgHVDL2B0Yy6hnkOIa5mbmomSrV6poWS8om12qbC0mku4YRyKtE9Dv8AEz6C5hl2HhHdtraQ5yxXFj8FMcazRkUB6olCu5mCZ6kuYmJ43MWal6rWqr+8l6ajri4mlmTnmRv5ttuXy9JOQaimWNQDAM4phTGqLGn4TdjDEdxqbcjosUD7oJo1YPWDl+SKEDMaEtAqV8qJNgS1SpDBWS5lw9ZngwX0yUykTm1bfFU8FEuoF9CMhHqMFSjNqA+MiXn7tRTNPd0gOsRT13Nq4fm2SzjDKnWkjHCcsqHBdbONiOrsRnjJc/KiQsnDZyVEKrADQzXFpTCDw9RYRr/3uRWaNBhFY3OhqMlo8k5iAD8lax0ELFPqJrlsaJruU6/j45FA44aK7MpOrhurU6c0GPeoZNnY2hNECNk18pSxyO9+3c1fL8nQWZ9xRvn0Ot+zgSZ1PI+euiK01Ppbvp1tZ0Cv9anIevp7LrU7u1lfnZR9XIOFAAAOw==',
            // 1 Village
            'R0lGODlhOQA5AMQAAEw0NF5lj5WAdmBPZXpwYC1qRSopQFRTYjw8TklIVyEgMGZMSR1KQTs2Q1tKU0Y/Sx1ZSVc+OYRnXjl2Tx1uUwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAA5ADkAAAX/YCCOoyQIZoqa6OK6URy9s2zLQG7nAFlKwBTwxALOFjUb7QbD6QARni8QLA5VwdgSKeMyvVEeNDcVVlfEk6DWTN7eO7GUdF6d72C4/i0n/4J2VYISe4V6fT1/g4tVho5xYoqMRHVvLY98kVSMgIGdNi1tmDFjPZynZzJBL6KPT6iwJqoSrEt7eWOxpwJcQLWsbw7Cww/FDVERBYLKuidIvqzQbg4DA8LW1APFDw0AEIIQzLC8LrTR0F7D6uvbDeFBBRDfuuXVDg/lSKzY2evq2/GYhZtXRdyZBRLYPUiCBJu9YQ/5FRtYoKI8ZeLeCVrw8Nq9Bsdi+LvGzyM2BuFQ/waEsIDlgngEfakr+TGkgZs4c+rUyaAng3gqC/zsGa+WR3/2QC4AybSp06c+IfiMKk/qzwU+d2q9GYFbA2HbHoD1ys2YVKtoq6pN20AsyJpMvUYAGVasgrsK2jWdurYqhbU9IbQNe1cvSAaDtznAizcs08Dy/kamQLkyZXkMxG5jDPaxZsKM894j2xeC5dOWEyR+wNhxAwSr7YZ27U7yZAoTTuemcCCBatCFi338LXZ06LzCvU7OvRv1gd6+YY9trRd2XdazDaPGzfu5b9/PEYinW0zBTdHtrI9dnH00SNy5n8uHnqC3eASQIZu2bbUneeF35VTXWw/I9x109+m3n/9aFBBAAH9VZZbYYjoVZ8xXoyVwn3gK+rXdBAQ0N4FafN0m2VQ9SYQfSqVtxx1lE8T4Yl+olYZZRxN5qJuML1YGooiX7QdfkDZCNBZqzblo2Y9Jwuegj9tVNZM1xujm4nwHiAffbjHyCOOSYFKjEDdfWjbffd/5tmWXMfb2nJLcTUDSP1VShiUC0YGHJgJrtgnefM55N5OY7jUgH55ppomAd1qyOYF3WSKqYXfegdfRnBeGhyeimm6IgDyO2qdonon6ttVOenqqKn6gsknBpvXZt+F8Gj711HcJshhhiRDEGOJuulIlVaz3XThYUw9Et+JpNvbqaI0m6sfAXU951QDCVWXC2eWvPcKpVmNxxcWikl7CuG2XO8JJQWPCIaujlTv6iq6627HbjnJC0uuoq/SCaW+7IL3r4r7PktskZf8aw824XCZJ8K/zbtmvAcGNxRSDSO7roIOuHjxwbuddd9ha5hLs68b8krsdTmF9pGtkJrOJMscR90sZy2Hpt6SjKMtMcLzw3nyTMFF9fDLEMddsM4ooaXt00kwqTS/GTpsMZczZImlZvupanTHWPpZrc7xif3hyymPr63HZW/bscboUhAAAOw==',
            // 2 Escaped
            'R0lGODlhOQA5AMQAAB1BO3h3hTs2QyEgMHpwYGFgblRTYkdHWZqGNjw8Tkw0NCwsWWZMSVc+OZyUKjl2T4uKmCopQB1KQS1qRV5lj1JahB1ZSVhgih1uUwAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAA5ADkAAAX/YCWOZGmeaKquULu+cDwGreu+d4w4DgIHtJpQJaytdrykbwUMNgMqYO2JQiaVsmylBVxdvw6t6UIum89kkxXcU6Hf8PiZ/S3J7/g3/TrK+/9rYAh/hH97DoV+NXmBSmeLiWUthI2DkkUBkXAQmXJIlmYMRZwXk5qnoaKjkHcUrq8UqGQQDQ2qC0JAZ7C8vb69aKO1DBHFuE0Qv8rLy6u0w8URC77TzNbKXAEUnAHDDMTG1a7SuELb2tfprxHettEL09Hko+i84uv3y8W1tt/g8PLILZBirBe5de+sGWugoF8/gRPewVsQkCIFaQkvRphAEZ4vaRqlMfTmj5wFYwI7/6oMtxHgRgscJ1KYMA7lOwUNHfpbMAEmRnIRpcUMyhMmxQgSevKceBIlz2IccfL79hCmBXgRi0ZU2jOrVZ49JSS9qjVcV6VS2/mTYCFp141dLVjt+VJsz7ltObZtCs9q3rQkGdgaO/auXL8TCs9lK/ar3a2JYY7FmVNnv72PYYadELdx26RuxRamK9ezWMpTvykQ/G30Xs6bI4OOnHg0W82SE8NGnZOq6m95cecdO9y15NucFXe2QLmhv1qrGUTXLTduWLxW2dKmfn2zZtQMBogXPIwhg7CKP3NHzxlve7va4zLHGV78+H6CG55lDDt7dezo4dXYgBNIVZ99luH0Wf9uh3lnWnbxNaZbaD1JZd+FtpSnQGi3wRfgbNstSBuEMNEnD4LkQacAAABoxuKLAHQlwYvVefehaLBJYGJAEeQkFU4CCPBikAJIECSMR7JoAYxMNtkiAFIFlMCUgEFnpGhYilVkkaIFqaWRXG4J5pg7RjDlAQcYYACaaxqQ5WFwvvlZlnTWqWNDxZyZpgEFGJAAmgfAKeighBZq6HwN6clnAYyqKRcGh8IJaaGTVjqpoJQJ9qeajHZagAUYhAppqI8+aulhooIq6qqXomqgdAks2ikBrIr6QK245hrqramqGqpzGcbKKQEEPMCrrsgmm+ut/CTKJgbGRrvqscraWi17q6hJECioBWBQbLHGVkttsuNiuyFbCahqwK4PEBvutfDqeq6k1hoLbrnxxisaqrjaK624rOI77aqe+RpwtAgPnG+1numK8L0CL6xrY+QinLDEuyZ7W8DTPnyxwiDnu7HAD0Mccbz4mupwtMS6+y/GyKq8LMstfwxzriEAADs='
        ];
        return backgrounds[bgType];
    }

    /**
    * @notice return a fill color for the frame
    * @param frameType frame type
    * @return string of css color variable
    */
    function _frame(uint256 frameType)
        internal
        pure
        returns (string memory)
    {
        string[8] memory frames = [
            'black',
            'var(--dm17)',
            'var(--dm26)',
            'var(--dm4)',
            'url(%2523s)',
            'url(%2523g)',
            'url(%2523f)',
            'url(%2523c)'
        ];
        return frames[frameType];
    }

    /**
    * @notice render a double-encoded data URI for the profile SVG
    * @param spawnType chamber type of spawn
    * @param body body of the SVG markup
    * @param bgType the background type of the image
    * @param frameType the frame type of the image
    * @return string of svg as a data uri
    */
    function render(string memory spawnType, string memory body, uint256 bgType, uint256 frameType)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            'data:image/svg+xml,%253Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'100%\' height=\'100%\' viewBox=\'0 0 57 57\' preserveAspectRatio=\'xMidYMid meet\'%253E%253Cstyle%253E*{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor}:root{--dm0:%25237a09fa;--dm1:%252337104f;--dm2:%2523661e92;--dm3:%2523db3ffd;--dm4:%2523630460;--dm5:%2523b0151a;--dm6:%2523ed1c24;--dm7:%2523f01343;--dm8:%2523876776;--dm9:%2523b48a9e;--dm10:%2523f0b8d3;--dm11:%2523f7941d;--dm12:%2523fff200;--dm13:%2523fcd617;--dm14:%2523fbd958;--dm15:%2523fae391;--dm16:%2523005d2e;--dm17:%2523007c3d;--dm18:%2523209e35;--dm19:%252300a651;--dm20:%252339b54a;--dm21:%2523aaff4f;--dm22:%25232d1c50;--dm23:%252309080b;--dm24:%25231b1a2c;--dm25:%25231e205e;--dm26:%25232e3192;--dm27:%25231452cc;--dm28:%25231dc0ed;--dm29:%2523393754;--dm30:%25232a4c69;--dm31:%25231e8492;--dm32:%25238393ca;--dm33:%2523404247;--dm34:%252356585f;--dm35:%25235a5a5a;--dm36:%2523707070;--dm37:%2523898989;--dm38:%2523b7b7b7;--dm39:%2523dddddd;--dm40:%25234f3810;--dm41:%252392671e;--dm42:%2523bbaa6d;--dm43:%25233e3531;--dm44:%2523534741;--dm45:%25237d5e52;--dm46:%252347210e;--dm47:%2523603114;--dm48:%252380421b;--dm49:%2523984f1d;--dm50:%25233e2309;--dm51:%2523522b0c;--dm52:%252376451d;--dm53:%252394623d;--dm54:%2523cf9768;--dm55:%2523efc088;--dm56:%2523f1c998;--dm57:%2523e4af8f;--dm58:%2523e9c4af;--dm59:%2523f0d0bd;--dmw15:rgba(255,255,255,.15);--dmw25:rgba(255,255,255,.25);--dmb15:rgba(0,0,0,.15);--dmb2:rgba(0,0,0,.2);--dmb25:rgba(0,0,0,.25);--dmb35:rgba(0,0,0,.35);--dmb4:rgba(0,0,0,.4);--dmb5:rgba(0,0,0,.5);--dmb6:rgba(0,0,0,.6);--dmb68:rgba(0,0,0,.68);--dmtl:rgba(255,215,0,.1);--dmc:var(--dm29);--dme:white;}.c0{fill:var(--dm6)}.c1{fill:var(--dm11)}.c2{fill:var(--dm12)}.c3{fill:var(--dm18)}.c4{fill:var(--dm28)}.c5{fill:var(--dm27)}.c6{fill:var(--dm0)}.c7{fill:var(--dm3)}%253C/style%253E%253Cdefs%253E%253Cpattern id=\'c\' width=\'2\' height=\'2\' viewBox=\'0 0 2 2\' patternUnits=\'userSpaceOnUse\'%253E%253Cpath d=\'M0,0h2v2h-2z\' fill=\'var(--dm38)\'/%253E%253Cpath d=\'M0,0h1v1h1v1h-1v-1h-1z\' fill=\'var(--dm33)\'/%253E%253C/pattern%253E%253ClinearGradient id=\'s\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'var(--dm38)\'/%253E%253Cstop offset=\'100%2525\' stop-color=\'var(--dm37)\'/%253E%253C/linearGradient%253E%253ClinearGradient id=\'g\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'var(--dm42)\'/%253E%253Cstop offset=\'100%2525\' stop-color=\'var(--dm41)\'/%253E%253C/linearGradient%253E%253ClinearGradient id=\'f\' x1=\'0\' x2=\'1\' y1=\'0\' y2=\'1\'%253E%253Cstop offset=\'0%2525\' stop-color=\'%25238393ca\'%253E%253Canimate attributeName=\'stop-color\' values=\'%25238393ca;%25231dc0ed;%2523aaff4f;%2523db3ffd;%25238393ca\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'33%2525\' stop-color=\'%25231dc0ed\'%253E%253Canimate attributeName=\'stop-color\' values=\'%25231dc0ed;%2523aaff4f;%2523db3ffd;%25238393ca;%25231dc0ed\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'66%2525\' stop-color=\'%2523aaff4f\'%253E%253Canimate attributeName=\'stop-color\' values=\'%2523aaff4f;%2523db3ffd;%25238393ca;%25231dc0ed;%2523aaff4f\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253Cstop offset=\'100%2525\' stop-color=\'%2523db3ffd\'%253E%253Canimate attributeName=\'stop-color\' values=\'%2523db3ffd;%25238393ca;%25231dc0ed;%2523aaff4f;%2523db3ffd\' dur=\'6s\' repeatCount=\'indefinite\'%253E%253C/animate%253E%253C/stop%253E%253C/linearGradient%253E%253C/defs%253E%253Cimage href=\'data:image/gif;base64,',
            _background(bgType),
            '\'/%253E%253Cpath d=\'M0,0h57v57h-57z\' class=\'c',
            spawnType,
            (bgType == 0 ? '\' style=\'mix-blend-mode:color\'/%253E' : '\' style=\'display:none\'/%253E'),
            body,
            '%253Cpath d=\'M0,0h57v57h-57v-56h1v55h55v-55h-56z\' fill=\'',
            _frame(frameType),
            '\'/%253E%253C/svg%253E'
        ));
    }
}