/**
 *Submitted for verification at Etherscan.io on 2022-06-11
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bool neg = false;
        int256 temp;
        int256 abs_value;
        if (value == 0) {
            return "0";
        }
        if (value < 0) {
            neg = true;
            temp = int(0 - value);
        } else {
            temp = int(value);
        }
        abs_value = temp;

        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (abs_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(abs_value % 10)));
            abs_value /= 10;
        }

        return neg? string(abi.encodePacked('-', string(buffer))) : string(buffer);
    }

}

struct Orbit2D {
    int256 a;
    int256 e;
    int256 M;
    int256 T;
    int256 n;
    int256 a_rate;
    int256 e_rate;
}

struct Orbit3D {
    int256 a;
    int256 e;
    int256 M;
    int256 T;
    int256 Omega;
    int256 omega;
    int256 I;
    int256 a_rate;
    int256 e_rate;
    int256 I_rate;
    int256 Omega_rate;
    int256 omega_rate;
    Orbit2D orbit2d;
}


pragma solidity ^0.8.0;

library Orbit2DFuns {
    uint8 constant Decimals = 8;
    int256 constant PI = 314159265;

    /**
     * Sets the mean angular velocity (n) for the class
     * Needs to be run every time the period (T) is set or updated
     */
    function _update_n( Orbit2D storage self ) internal {
        self.n = 100 * 2 * PI / self.T;     //100*self.n to correct closely
    }

    /**
     * To be used for changes in orbital parameters, e.g. perihelion shift
     */
    function update( Orbit2D storage self, string memory key, int256 value ) internal {
        if (keccak256(bytes(key)) == keccak256(bytes('a')))
            self.a = value;
        if (keccak256(bytes(key)) == keccak256(bytes('e')))
            self.e = value;
        if (keccak256(bytes(key)) == keccak256(bytes('M')))
            self.M = value;
        if (keccak256(bytes(key)) == keccak256(bytes('T'))) {
            self.T = value;
            self.n = 100 * 2 * PI / value;
        }
    }


    // E = fsolve( lambda E: self._Kepler_equation( E, M ), self.E_init )  # actual eccentric anomaly
    function Kepler_fsolve(int256 M, int256 e) internal pure returns(int256, bool)
    {
        // condition to check if fsolve is success.
        // fsolve_cond = (np.pi-2/E0) * (np.pi-2/E0) - 4*(np.pi*np.pi/4 - 2 - 2*M0/E0) : Python format
        int256 fsolve_cond = (PI- int(10**Decimals) * 2*int(10**Decimals)/e);
        int256 temp;
        fsolve_cond = fsolve_cond * fsolve_cond;
        temp = int(10**Decimals) * 2*int(10**Decimals)*M/e;
        temp = 4*(PI*PI/4 - int(10**Decimals) * 2*int(10**Decimals) - temp );
        fsolve_cond = fsolve_cond - temp;

        if(fsolve_cond > 0) {
            int256 E0 = ((PI- int(10**Decimals) * 2*int(10**Decimals)/e) + int(MathLib.sqrt(uint(fsolve_cond))))/2;
            int256 E1 = ((PI- int(10**Decimals) * 2*int(10**Decimals)/e) - int(MathLib.sqrt(uint(fsolve_cond))))/2;
            int256 E0_offset = E0- e*MathLib.sin(int(E0))/int(10**Decimals);
            int256 E1_offset = E1- e*MathLib.sin(int(E1))/int(10**Decimals);
            int256 E = MathLib.abs(E0_offset) < MathLib.abs(E1_offset) ? E0:E1;

            for(uint i=0; i<5; i++) {
                temp = int(10**Decimals) * (E - e*MathLib.sin(int(E))/int(10**Decimals) - M);
                temp = E - temp/(int(10**Decimals) - MathLib.cos(int(E))/int(10**Decimals));
                E = temp;
            }

            return(E, true);

        } else {
            return(0, false);
        }

    }



    /**
     * Arguments: t [sec] - relative time from point zero (default J2000 epoch)
     * Returns: radius [AU] and true anomaly [rad]
     */
    function get_rv( Orbit2D storage self, int256 t ) internal view returns (int256, int256) {

        int256 M = self.n * t/100  + self.M;  // actual mean anomaly
        int256 E;                         // actual eccentric anomaly
        int256 temp;                      // Temporary memory for deep computations
        bool fsolve_cond;
        int256 orbit2D_a = self.a + self.a_rate * t /3153600000;
        int256 orbit2D_e = self.e + self.e_rate * t /3153600000;

        (E, fsolve_cond) = Kepler_fsolve(M, orbit2D_e);

        if(fsolve_cond) {
            // Radius (distance from baricenter) => r = self.a * ( 1.0 - self.e * np.cos( E ) ) : Python format
            int256 r = orbit2D_a * ( int(10**Decimals) - orbit2D_e * MathLib.cos(E)/int(10**Decimals) ) / (int(10**Decimals));
            // True anomaly => v = 2.0 * np.arctan( np.sqrt( ( 1.0 + self.e ) / ( 1.0 - self.e ) ) * np.tan( E / 2.0 ) ) : Python format                            // radius (distance from baricenter)
            temp = int(MathLib.sqrt(uint( int(10**Decimals) * int(10**Decimals) * (int(10**Decimals) + orbit2D_e )/( int(10**Decimals) - orbit2D_e ))));
            int256 ratio = temp * MathLib.sin(int(E/2))/MathLib.cos(int(E/2));
            temp = int(MathLib.arctan(int(ratio)));
            int256 v = 2 * temp  ;  // true anomaly
            return(r, v);
        } else {
            return(0, 0);
        }

    }


    /**
     * Same as get_rv() but returns the objects position in cartesian coordinates
     * Returns: x, y [AU] - x-axis is in the direction of pericenter, y-axis is right-hand perpendicular
     */
    function get_xy( Orbit2D storage self, int256 t ) internal view returns (int256, int256) {
        int256 r;
        int256 v;
        (r, v) = get_rv(self, t);

        int256 x = r * MathLib.cos(int(v))/int(10**Decimals);
        int256 y = r * MathLib.sin(int(v))/int(10**Decimals);

        return(x, y);

    }

}

pragma solidity ^0.8.0;

library Orbit3DFuns {

    uint8 constant Decimals = 8;
    int256 constant PI = 314159265;

    /**
     * Updates class parameters
     * To be used for changes in orbital parameters, e.g. perihelion shift
     */
    function update( Orbit3D storage self, string memory key, int256 value ) internal {
        if (keccak256(bytes(key)) == keccak256(bytes('a')))
            self.a = value;
        if (keccak256(bytes(key)) == keccak256(bytes('e')))
            self.e = value;
        if (keccak256(bytes(key)) == keccak256(bytes('M')))
            self.M = value;
        if (keccak256(bytes(key)) == keccak256(bytes('T')))
            self.T = value;
        if (keccak256(bytes(key)) == keccak256(bytes('Omega'))) {
            self.Omega = value;
        }
        if (keccak256(bytes(key)) == keccak256(bytes('omega'))) {
            self.omega = value;
        }
        if (keccak256(bytes(key)) == keccak256(bytes('I'))) {
            self.I = value;
        }

        Orbit2DFuns.update(self.orbit2d, key, value);
    }



    function get_euler_matrix( Orbit3D storage self, int256 t) internal view returns(int256,int256,int256,int256,int256,int256)
    {
        int256[3][3] memory euler_matrix;
        // int256 temp;
        euler_matrix[0][2] = self.Omega + self.Omega_rate * t /3153600000;
        euler_matrix[1][2] = self.I + self.I_rate * t /3153600000;
        euler_matrix[2][2] = self.omega + self.omega_rate * t /3153600000;

        int256 cosO = MathLib.cos(euler_matrix[0][2]);
        int256 sinO = MathLib.sin(euler_matrix[0][2]);

        int256 cosI = MathLib.cos(euler_matrix[1][2]);
        int256 sinI = MathLib.sin(euler_matrix[1][2]);

        int256 coso = MathLib.cos(euler_matrix[2][2]);
        int256 sino = MathLib.sin(euler_matrix[2][2]);

        euler_matrix[0][0] = (int(10**Decimals)*cosO*coso- sinO*sino*cosI)/(int(10**Decimals)*int(10**Decimals));
        euler_matrix[0][1] = (-int(10**Decimals)*cosO*sino- sinO*coso*cosI)/(int(10**Decimals)*int(10**Decimals));
        // euler_matrix[0][2] = sinO*sinI/int(10**Decimals);
        euler_matrix[1][0] = (int(10**Decimals)*sinO*coso + cosO*cosI*sino)/(int(10**Decimals)*int(10**Decimals));
        euler_matrix[1][1] = (cosO*coso*cosI -int(10**Decimals)*sinO*sino)/(int(10**Decimals)*int(10**Decimals));
        // euler_matrix[1][2] = -cosO*sinI/int(10**Decimals);
        euler_matrix[2][0] = sinI*sino/int(10**Decimals);
        euler_matrix[2][1] = sinI*coso/int(10**Decimals);
        // euler_matrix[2][2] = cosI;

        return(euler_matrix[0][0], euler_matrix[0][1], euler_matrix[1][0], euler_matrix[1][1], euler_matrix[2][0], euler_matrix[2][1]);

    }


    /**
     * Argument: t [sec] - time since time zero [default to J2000 epoch]
     * Returns: objects possition x, y, z in [AU] - x is directed at vernal equinox; y,z are right-handed ortogonal
     */
    function get_xyz( Orbit3D storage self, int256 t) internal view returns (int256, int256, int256) {
        int256 p_2d_x;
        int256 p_2d_y;
        int256 euler_matrix_0_0;
        int256 euler_matrix_0_1;
        int256 euler_matrix_1_0;
        int256 euler_matrix_1_1;
        int256 euler_matrix_2_0;
        int256 euler_matrix_2_1;

        (euler_matrix_0_0, euler_matrix_0_1, euler_matrix_1_0, euler_matrix_1_1, euler_matrix_2_0, euler_matrix_2_1) = get_euler_matrix(self, t);

        (p_2d_x, p_2d_y) = Orbit2DFuns.get_xy(self.orbit2d, t);

        int256 x = (euler_matrix_0_0 * p_2d_x + euler_matrix_0_1 * p_2d_y)/int(10**Decimals);
        int256 y = (euler_matrix_1_0 * p_2d_x + euler_matrix_1_1 * p_2d_y)/int(10**Decimals);
        int256 z = (euler_matrix_2_0 * p_2d_x + euler_matrix_2_1 * p_2d_y)/int(10**Decimals);

        return(x, y, z);

    }

    /**
     * Argument: t [sec] - time since time zero [default to J2000 epoch]
     * Returns: objects possition x, y in [AU] - x is directed at vernal equinox; y is right-handed ortogonal
     */
    function get_xy( Orbit3D storage self, int256 t) internal view returns (int256, int256) {
        int256 p_2d_x;
        int256 p_2d_y;
        (p_2d_x, p_2d_y) = Orbit2DFuns.get_xy(self.orbit2d, t);

        return(p_2d_x, p_2d_y);
    }

}


pragma solidity ^0.8.0;
pragma abicoder v2;

contract Orbit {

    using Orbit2DFuns for Orbit2D;
    using Orbit3DFuns for Orbit3D;
    using Strings for int256;
    // int256[3][3] public matrix;
    Orbit2D orbit2d;
    Orbit3D orbit3d;
    mapping (bytes => Orbit3D) private Solar_System_Keplerian_Elements;

    constructor() {
        orbit2d =  Orbit2D({a:38709893, e:20563069, M: 305073760, T:760065407544000, n:8267, a_rate:37, e_rate:1906 });
        orbit3d =  Orbit3D({a:38709893, e:20563069, M: 305073760, T:760065407544000, I:12225804, Omega:84354677, omega:50832330,
                            a_rate:37, e_rate:1906, I_rate:-10380, Omega_rate:-218761, omega_rate:498846, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Mercury')] = orbit3d;

        orbit2d =  Orbit2D({a:72333199, e:677323, M: 88046188, T:1940826194496000, n:3237, a_rate:390, e_rate:-4107});
        orbit3d =  Orbit3D({a:72333199, e:677323, M: 88046188, T:1940826194496000, I:5924887, Omega:133833051, omega:95735306,
                            a_rate:390, e_rate:-4107, I_rate:-1377, Omega_rate:-484667, omega_rate:489351, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Venus')] = orbit3d;

        orbit2d =  Orbit2D({a:100000011, e:1671022, M: -4333373, T:3155814950400000, n:1991, a_rate:56, e_rate:-439});
        orbit3d =  Orbit3D({a:100000011, e:1671022, M: -4333373, T:3155814950400000, I:87, Omega:0, omega:179676742,
                            a_rate:56, e_rate:-439, I_rate:-0, Omega_rate:0, omega_rate:564218, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('EM')] = orbit3d;

        orbit2d =  Orbit2D({a:152366231, e:9341233, M: 33881169, T:5936087921702400, n:1058, a_rate:1847, e_rate:7882});
        orbit3d =  Orbit3D({a:152366231, e:9341233, M: 33881169, T:5936087921702400, I:3229923, Omega:86530876, omega:499971031,
                            a_rate:1847, e_rate:7882, I_rate:-14192, Omega_rate:-510637, omega_rate:1286280, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Mars')] = orbit3d;

        orbit2d =  Orbit2D({a:520336301, e:4839266, M: 34296644, T:37427965311744000, n:168, a_rate:-11607, e_rate:-13253});
        orbit3d =  Orbit3D({a:520336301, e:4839266, M: 34296644, T:37427965311744000, I:2278178, Omega:175503590, omega:-149753264,
                            a_rate:-11607, e_rate:-13253, I_rate:-3206, Omega_rate:357253, omega_rate:13676, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Jupiter')] = orbit3d;

        orbit2d =  Orbit2D({a:953707032, e:5415060, M: -74154886, T:92970308438784000, n:68, a_rate:-125060, e_rate:-50991});
        orbit3d =  Orbit3D({a:953707032, e:5415060, M: -74154886, T:92970308438784000, I:4336200, Omega:198470185, omega:-37146017,
                            a_rate:-125060, e_rate:-50991, I_rate:3379, Omega_rate:-503838, omega_rate:-227406, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Saturn')] = orbit3d;

        orbit2d =  Orbit2D({a:1919126393, e:4716771, M: 248304397, T:265120013983104000, n:24, a_rate:-196176, e_rate:-4397});
        orbit3d =  Orbit3D({a:1919126393, e:4716771, M: 248304397, T:265120013983104000, I:1343659, Omega:129555580, omega:168833308,
                            a_rate:-196176, e_rate:-4397, I_rate:-4240, Omega_rate:74012, omega_rate:638174, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Uranus')] = orbit3d;

        orbit2d =  Orbit2D({a:3006896348, e:858587, M: 453626222, T:520078303825920000, n:12, a_rate:26291, e_rate:5105});
        orbit3d =  Orbit3D({a:3006896348, e:858587, M: 453626222, T:520078303825920000, I:3087784, Omega:229897718, omega:-151407906,
                            a_rate:26291, e_rate:5105, I_rate:617, Omega_rate:-8878, omega_rate:-553842, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Neptune')] = orbit3d;

        orbit2d =  Orbit2D({a:3948168677, e:24880766, M: 25939170, T:782957689194239900, n:8, a_rate:262910, e_rate:51050});
        orbit3d =  Orbit3D({a:3948168677, e:24880766, M: 25939170, T:782957689194239900, I:29917997, Omega:192515872, omega:198554397,
                            a_rate:262910, e_rate:51050, I_rate:6173, Omega_rate:-88778, omega_rate:-473941, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Pluto')] = orbit3d;

        orbit2d =  Orbit2D({a:311, e:5554400, M: -392762524, T:236059142400000, n:26617, a_rate:0, e_rate:0});
        orbit3d =  Orbit3D({a:311, e:5554400, M: -392762524, T:236059142400000, I:9000197, Omega:218243998, omega:241393696,
                            a_rate:0, e_rate:0, I_rate:0, Omega_rate:0, omega_rate:0, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Earth')] = orbit3d;

        orbit2d =  Orbit2D({a:253171, e:5554400, M: 235556006, T:236059142400000, n:26617, a_rate:0, e_rate:0});
        orbit3d =  Orbit3D({a:253171, e:5554400, M: 235556006, T:236059142400000, I:9000197, Omega:218243998, omega:-72765569,
                            a_rate:0, e_rate:0, I_rate:0, Omega_rate:0, omega_rate:0, orbit2d:orbit2d });
        Solar_System_Keplerian_Elements[bytes('Moon')] = orbit3d;

    }

    /**
     * Returns the 3D position of the object planet relative to the observer planet.
     * integer, integer, integer.
     *
     * @param object object planet name
     * @param observer observer planet name
     *        ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon']
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return 3D relative position
     */
    function get_relative_3D_pos(string memory object, string memory observer, int256 t ) public view returns (int256, int256, int256) {
        int256 pos_x;
        int256 pos_y;
        int256 pos_z;
        int256 obs_x = 0;
        int256 obs_y = 0;
        int256 obs_z = 0;

        // objective planet's absolute position.
        (pos_x, pos_y, pos_z) = get_absolutive_3D_pos(object, t);
        // observer planet's absolute position.
        (obs_x, obs_y, obs_z) = get_absolutive_3D_pos(observer, t);
        return (pos_x-obs_x, pos_y-obs_y, pos_z-obs_z);
    }


    /**
     * Returns the 3D positions list of the all solar planets relative to the observer planet.
     * string
     *
     * @param observer observer planet name
     *        ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon']
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return 3D relative position list
     */
    function get_relative_all_3D_pos(string memory observer, int256 t ) public view returns (string[] memory) {
        int256 pos_x;
        int256 pos_y;
        int256 pos_z;
        int256 obs_x = 0;
        int256 obs_y = 0;
        int256 obs_z = 0;
        string[11] memory planet_list = ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon'];
        string[] memory result_list = new string[](11);

        for (uint i=0; i< planet_list.length; i++) {
            (pos_x, pos_y, pos_z) = get_relative_3D_pos(planet_list[i], observer, t);
            result_list[i] = string(abi.encodePacked(planet_list[i], "_", (pos_x-obs_x).toString(), "_", (pos_y-obs_y).toString(), "_", (pos_z-obs_z).toString() ));
        }

        return result_list;
    }


    /**
     * Returns the absolutive 3D position of the object planet.
     * integer, integer, integer.
     *
     * @param object object planet name
     *        ['O', 'Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon']
     *        O means (0,0,0) position
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return 3D absolutive position
     */
    function get_absolutive_3D_pos(string memory object, int256 t ) public view returns (int256, int256, int256) {
        int256 pos_x;
        int256 pos_y;
        int256 pos_z;

        if( keccak256(bytes(object)) == keccak256(bytes('O'))) {
            return (0, 0, 0);
        }

        // objective planet's absolute position.
        (pos_x, pos_y, pos_z) = Solar_System_Keplerian_Elements[bytes(object)].get_xyz(t);
        if( keccak256(bytes(object)) == keccak256(bytes('Earth')) || keccak256(bytes(object)) == keccak256(bytes('Moon'))  ) {
            // Earth and Moon are child planet of EM planet.
            int256 EM_X = 0;
            int256 EM_Y = 0;
            int256 EM_Z = 0;
            (EM_X, EM_Y, EM_Z) = Solar_System_Keplerian_Elements[bytes('EM')].get_xyz(t);
            pos_x = pos_x + EM_X;
            pos_y = pos_y + EM_Y;
            pos_z = pos_z + EM_Z;
        }

        return (pos_x, pos_y, pos_z);
    }


    /**
     * Returns the absolutive 3D positions list of the all solar planets.
     * string
     *
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return 3D absolutive position list
     */
    function get_absolutive_all_3D_pos(int256 t ) public view returns (string[] memory) {
        int256 pos_x;
        int256 pos_y;
        int256 pos_z;
        string[11] memory planet_list = ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon'];
        string[] memory result_list = new string[](11);

        for (uint i=0; i< planet_list.length; i++) {
            (pos_x, pos_y, pos_z) = get_absolutive_3D_pos(planet_list[i], t);
            result_list[i] = string(abi.encodePacked(planet_list[i], "_", pos_x.toString(), "_", pos_y.toString(), "_", pos_z.toString() ));
        }

        return result_list;
    }


    /**
     * Returns the position of the object planet on the sky relative to the observer.
     * integer, integer.
     *
     * @param object object planet name
     * @param observer observer planet name
     *        ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon']
     * @param obs_latitude latitude of the observer (relevant only for coordinates = 'horizontal')
     * @param obs_longitude longitude of the observer (relevant only for coordinates = 'horizontal')
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return 3D relative position
     */
    function get_sky_pos(string memory object, string memory observer, int256 obs_latitude, int256 obs_longitude, int256 t) public view returns (int256, int256) {
        int256 pos_x;
        int256 pos_y;
        int256 pos_z;
        int256 temp_a = 0;
        int256 temp_b = 0;
        int256 temp_c = 0;

        // Get relative 3D position of object planet in the space
        (pos_x, pos_y, pos_z) = get_absolutive_3D_pos(object, t);
        (temp_a, temp_b, temp_c) = get_absolutive_3D_pos(observer, t);

        pos_x = pos_x - temp_a;
        pos_y = pos_y - temp_b;
        pos_z = pos_z - temp_c;

        temp_a = obs_latitude * 314159265 / (180 * 10**8);
        temp_b = obs_longitude * 314159265 / (180 * 10**8);

        // Transforms positions in space to positions on the sky
        (temp_a, temp_b) = MathLib.get_sky_positions(pos_x, pos_y, pos_z, 40910000, temp_a, temp_b, t);

        return (temp_a, temp_b);
    }


    /**
     * Returns the sky positions list of the all solar planets.
     * string
     *
     * @param observer observer planet name
     *        ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon']
     * @param obs_latitude latitude of the observer (relevant only for coordinates = 'horizontal')
     * @param obs_longitude longitude of the observer (relevant only for coordinates = 'horizontal')
     * @param t UTC time index from 2000-01-01 12:00:00 (second unit)
     * @return sky position list
     */
    function get_all_sky_pos(string memory observer, int256 obs_latitude, int256 obs_longitude, int256 t) public view returns (string[] memory) {
        int256 pos_a;
        int256 pos_A;
        string[11] memory planet_list = ['Mercury', 'Venus', 'EM', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'Earth','Moon'];
        string[] memory result_list = new string[](11);

        for (uint i=0; i< planet_list.length; i++) {
            if( keccak256(bytes(planet_list[i])) != keccak256(bytes(observer))) {
                (pos_a, pos_A) = get_sky_pos(planet_list[i], observer, obs_latitude, obs_longitude, t);
                result_list[i] = string(abi.encodePacked(planet_list[i], "_", pos_a.toString(), "_", pos_A.toString() ));
            }

        }
        return result_list;
    }

}