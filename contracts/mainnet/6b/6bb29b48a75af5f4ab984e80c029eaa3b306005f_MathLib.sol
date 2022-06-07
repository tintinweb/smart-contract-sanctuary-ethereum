/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MathLib {

    uint8 constant Decimals = 8;
    int256 constant PI = 314159265;

    function sqrt(uint256 y) internal pure returns (uint256) {
      uint256 result;
      if (y > 3) {
          result = y;
          uint256 x = y / 2 + 1;
          while (x < result) {
              result = x;
              x = (y / x + x) / 2;
          }
      } else if (y != 0) {
          result = 1;
      }

      return result;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x < 0 ? x*(-1) : x;
    }

    /**
     * Return the sine of an integer approximated angle as a signed 10^8
     * integer.
     *
     * @param input A 14-bit angle. This divides the circle into 628318530(2*PI)
     *               angle units, instead of the standard 360 degrees.
     * @return The sine result as a number in the range -10^8 to 10^8.
     */
    function sin(int256 input) internal pure  returns(int256)
    {
        int256[20] memory arctan_table = [int256(78539816), 39269908, 19634954, 9817477, 4908739, 2454369, 1227185, 613592, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory sin_table = [int256(70710678), 38268343, 19509032, 9801714, 4906767, 2454123, 1227154, 613588, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory cos_table = [int256(70710678), 92387953, 98078528, 99518473, 99879546, 99969882, 99992470, 99998118, 99999529, 99999882, 99999971, 99999993, 99999998, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000];

        while(input < 0) {
            input = input + 2*PI;
        }
        int256 _angle = int(input % 628318530);

        if (_angle > PI/2 && _angle <= PI) {
            _angle = PI - _angle;
        } else if(_angle > PI && _angle < PI*3/2) {
            _angle = PI - _angle;
        } else if(_angle >= PI*3/2 && _angle < 2*PI) {
            _angle = _angle - 2*PI;
        }

        int256 x = 100000000;
        int256 xnew = 100000000;
        int256 y = 0;
        int256 ynew = 0;
        int256 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < _angle)
            {
                xnew = (x*cos_table[i] - y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] + x*sin_table[i]) / 100000000;
                ang = ang + arctan_table[i];
            }

            else if (ang > _angle)
            {
                xnew = (x*cos_table[i] + y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] - x*sin_table[i]) / 100000000;
                ang = ang - arctan_table[i];
            }

            x = xnew;
            y = ynew;
        }
        return(y);
    }

    /**
     * Return the cos of an integer approximated angle as a signed 10^8
     * integer.
     *
     * @param input A 10^8 radian angle. This divides the circle into 628318530(2*PI)
     *               angle units, instead of the standard 360 degrees.
     * @return The cos result as a number in the range -10^8 to 10^8.
     */
    function cos(int256 input) internal pure returns(int256)
    {
        bool neg = false;
        int256[20] memory arctan_table = [int256(78539816), 39269908, 19634954, 9817477, 4908739, 2454369, 1227185, 613592, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory sin_table = [int256(70710678), 38268343, 19509032, 9801714, 4906767, 2454123, 1227154, 613588, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory cos_table = [int256(70710678), 92387953, 98078528, 99518473, 99879546, 99969882, 99992470, 99998118, 99999529, 99999882, 99999971, 99999993, 99999998, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000];

        while(input < 0) {
            input = input + 2*PI;
        }
        int256 _angle = int(input % 628318530);

        if (_angle > PI/2 && _angle <= PI) {
            _angle = PI - _angle;
            neg = true;
        } else if(_angle > PI && _angle < PI*3/2) {
            _angle = _angle - PI;
            neg = true;
        } else if(_angle >= PI*3/2 && _angle < 2*PI) {
            _angle = 2*PI - _angle;
        }

        int256 x = 100000000;
        int256 xnew = 100000000;
        int256 y = 0;
        int256 ynew = 0;
        int256 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < _angle)
            {
                xnew = (x*cos_table[i] - y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] + x*sin_table[i]) / 100000000;
                ang = ang + arctan_table[i];
            }

            else if (ang > _angle)
            {
                xnew = (x*cos_table[i] + y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] - x*sin_table[i]) / 100000000;
                ang = ang - arctan_table[i];
            }

            x = xnew;
            y = ynew;
        }

        if(neg)
        {
            return(-x);
        }
        else
        {
            return(x);
        }
    }

    /**
     * Return the tan of an integer approximated angle as a signed 10^8
     * integer.
     *
     * @param input A 10^8 radian angle. This divides the circle into 628318530(2*PI)
     *               angle units, instead of the standard 360 degrees.
     * @return The tan result as a number in the range -10^8 to 10^8.
     */
    function tan(int256 input) internal pure returns(int256)
    {
        // int256 PI = 314159265;
        int256[20] memory arctan_table = [int256(78539816), 39269908, 19634954, 9817477, 4908739, 2454369, 1227185, 613592, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory sin_table = [int256(70710678), 38268343, 19509032, 9801714, 4906767, 2454123, 1227154, 613588, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory cos_table = [int256(70710678), 92387953, 98078528, 99518473, 99879546, 99969882, 99992470, 99998118, 99999529, 99999882, 99999971, 99999993, 99999998, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000];

        while(input < 0) {
            input = input + 2*PI;
        }
        int256 _angle = int(input % 628318530);

        if (_angle >= PI/2 && _angle <= PI*3/2) {
            _angle = _angle - PI;
        } else if (_angle > 3*PI/2) {
            _angle = _angle - 3*PI/2;
        }

        int256 x = 100000000;
        int256 xnew = 100000000;
        int256 y = 0;
        int256 ynew = 0;
        int256 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (ang < _angle)
            {
                xnew = (x*cos_table[i] - y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] + x*sin_table[i]) / 100000000;
                ang = ang + arctan_table[i];
            }

            else if (ang > _angle)
            {
                xnew = (x*cos_table[i] + y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] - x*sin_table[i]) / 100000000;
                ang = ang - arctan_table[i];
            }

            x = xnew;
            y = ynew;
        }
        //now divide y and x
        int256 res; res = 0;
        int256 digit;
        int8 j;

        j = 1;
        while(j <= 8)
        {
            digit = y / x;
            res = res + digit;
            res = res * 10;
            y = (y % x)*10;
            j = j + 1;
        }

        return(res);
    }

    /**
     * Return the arcsin of an integer approximated ratio as a signed 10^8
     * integer.
     *
     * @param input A 10^8 ratio. This divides the (-1, 1) into (-10^8, 10^8)
     *               angle units, instead of the standard 360 degrees.
     * @return The arcsin result as a number in the range -10^8 to 10^8 .
     */

    function arcsin(int256 input) internal pure returns(int256)
    {
        int256[20] memory arctan_table = [int256(78539816), 39269908, 19634954, 9817477, 4908739, 2454369, 1227185, 613592, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory sin_table = [int256(70710678), 38268343, 19509032, 9801714, 4906767, 2454123, 1227154, 613588, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory cos_table = [int256(70710678), 92387953, 98078528, 99518473, 99879546, 99969882, 99992470, 99998118, 99999529, 99999882, 99999971, 99999993, 99999998, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000];

        int256 x = 100000000;
        int256 xnew = 100000000;
        int256 y = 0;
        int256 ynew = 0;
        int256 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (y < input)
            {
                xnew = (x*cos_table[i] - y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] + x*sin_table[i]) / 100000000;
                ang = ang + arctan_table[i];
            }

            else if (y > input)
            {
                xnew = (x*cos_table[i] + y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] - x*sin_table[i]) / 100000000;
                ang = ang - arctan_table[i];
            }

            x = xnew;
            y = ynew;
        }
        return(ang);
    }

    function arctan(int256 input) internal pure returns(int256)
    {
        int256[20] memory arctan_table = [int256(78539816), 39269908, 19634954, 9817477, 4908739, 2454369, 1227185, 613592, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory sin_table = [int256(70710678), 38268343, 19509032, 9801714, 4906767, 2454123, 1227154, 613588, 306796, 153398, 76699, 38350, 19175, 9587, 4794, 2397, 1198, 599, 300, 150];
        int256[20] memory cos_table = [int256(70710678), 92387953, 98078528, 99518473, 99879546, 99969882, 99992470, 99998118, 99999529, 99999882, 99999971, 99999993, 99999998, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000, 100000000];

        int256 x = 100000000;
        int256 xnew = 100000000;
        int256 y = input;
        int256 ynew = input;
        int256 ang = 0;

        uint8 i = 0;
        for (i = 0; i <= 19; i = i + 1)
        {
            if (y > 0)
            {
                xnew = (x*cos_table[i] + y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] - x*sin_table[i]) / 100000000;
                ang = ang + arctan_table[i];
            }

            else if (y < 0)
            {
                xnew = (x*cos_table[i] - y*sin_table[i]) / 100000000;
                ynew = (y*cos_table[i] + x*sin_table[i]) / 100000000;
                ang = ang - arctan_table[i];
            }

            x = xnew;
            y = ynew;
        }
        return(ang);
    }


    function arctan2(int256 Y, int256 X) internal pure returns(int256)
    {
        int256 alpha = arctan( abs(int256(10**Decimals) * Y / X));
        if( X < 0 && Y > 0) {
            alpha = PI - alpha;
        }
        if( X > 0 && Y < 0) {
            alpha = alpha * int256(-1);
        }
        if( X < 0 && Y < 0) {
            alpha = alpha - PI;
        }

        return(alpha);

    }


    /**
     * Conversion from ecliptic cartesian coordinates to equatorial ones
     * integer, integer, integer.
     *
     * @param cart_X cartesian X position
     * @param cart_Y cartesian Y position
     * @param cart_Z cartesian Z position
     * @param epsilon Axial tilt (40910000 = default value for the Earth )
     * @return The equatorial position.
     */
    function cart_ecl2cart_eq(int256 cart_X, int256 cart_Y, int256 cart_Z, int256 epsilon) internal pure returns(int256, int256, int256)
    {
        int256 equat_X = cart_X;
        int256 equat_Y = ( cart_Y*cos(epsilon) - cart_Z*sin(epsilon) )/int256( 10**Decimals );
        int256 equat_Z = ( cart_Y*sin(epsilon) + cart_Z*cos(epsilon) )/int256( 10**Decimals );
        return(equat_X, equat_Y, equat_Z);
    }


    /**
     * Conversion from cartesian to spherical coordinates
     * integer, integer.
     *
     * @param cart_X cartesian X position
     * @param cart_Y cartesian Y position
     * @param cart_Z cartesian Z position
     * @return The Spherical position.
     */
    function cart2sph(int256 cart_X, int256 cart_Y, int256 cart_Z) internal pure returns(int256, int256)
    {
        int256 norm = int256(sqrt(uint256(cart_X*cart_X + cart_Y*cart_Y + cart_Z*cart_Z)));
        int256 alpha = (arctan2(cart_Y, cart_X) + 2*PI) % (2*PI);
        int256 delta = arcsin(int256(10**Decimals) * cart_Z / norm);
        return(alpha, delta);
    }

    /**
     * Conversion from Equatorial to Horizontal coordinates (both spherical)
     * integer, integer.
     *
     * @param timeIndex UTC time index from 2000-01-01 12:00:00 (second unit)
     * @param RA Alpha value of Equatorial coordinates
     * @param DEC Delta value of Equatorial coordinates
     * @param lat latutude of the observer (north is positive) [rad]
     * @param lon longitude of the observer (east is positive) [rad]
     * @return return Horizontal position.
     */
    function sph_eq2sph_hor(int256 timeIndex, int256 RA, int256 DEC, int256 lat, int256 lon ) internal pure returns(int256, int256)
    {
        int256 temp;
        // calculating Greenwich Sideral Time
        int256 tu = int256( 10**Decimals ) * timeIndex / ( 24 * 3600 );
        int256 GST = 2*PI * ((77905727 + 100273781 * tu / int256( 10**Decimals )  ) % int256( 10**Decimals )) / int256(10**Decimals);
        // calculating Local Sideral Time
        int256 LST = GST + lon;

        // calculating the hour angle
        int256 h = LST - RA;
        // calculating the altitudes (a) and the azimuths (A) using spherical triangles
        int256 delta = DEC;

        temp = sin(lat) * sin(delta)/(int256(10**Decimals)) + cos(lat) * cos(delta) * cos(h)/(int256(10**(Decimals*2)));
        int256 a = arcsin(temp);

        temp = int256(-1) * cos(delta) * cos(h) * sin(lat)/(int256(10**(Decimals*2))) + sin(delta) * cos(lat)/(int256(10**Decimals));
        int256 A = int256(-1) * arctan2( cos(delta)*sin(h)/(int256(10**Decimals)), temp );

        return(a, A);
    }


    /**
     * Transforms positions in space to positions in the sky relative to an observer
     * integer, integer.
     *
     * @param pos_X positions X in space
     * @param pos_Y positions Y in space
     * @param pos_Z positions Z in space
     * @param obliquity Axial tilt (40910000 = default value for the Earth )
     * @param obs_latitude_rad latutude of the observer (north is positive) [rad]
     * @param obs_longitude_rad longitude of the observer (east is positive) [rad]
     * @param timeindex UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return return Sky position.
     */
    function get_sky_positions(int256 pos_X, int256 pos_Y, int256 pos_Z, int256 obliquity, int256 obs_latitude_rad, int256 obs_longitude_rad, int256 timeindex ) internal pure returns(int256, int256)
    {
        int256 RA;
        int256 DEC;
        int256 temp_1;
        int256 temp_2;
        int256 temp_3;

        (temp_1, temp_2, temp_3) = cart_ecl2cart_eq(pos_X, pos_Y, pos_Z, obliquity);
        (RA, DEC) = cart2sph(temp_1, temp_2, temp_3);

        (temp_1, temp_2) = sph_eq2sph_hor(timeindex, RA, DEC, obs_latitude_rad, obs_longitude_rad);

        return(temp_1, temp_2);
    }
}