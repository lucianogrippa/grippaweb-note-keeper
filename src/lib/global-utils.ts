
export function hasUpperCase(str: string, minUpperCase: number): boolean {
    return (new RegExp(`[A-Z]{${minUpperCase},}`, 'g')).test(str)
}

export function hasLowerCase(str: string,  minLowerCase: number): boolean {
    return (new RegExp(`[a-z]{${minLowerCase},}`, 'g')).test(str)
}

export function hasNumeric(str: string, minChars: number): boolean {
    return (new RegExp(`[0-9]{${minChars},}`, 'g')).test(str)
}

export function hasSpecialChars(str: string, minChars: number): boolean {
    return (new RegExp(`[\\.\\$\_\\-\\@\\[\\]\\{\\}\\?\\^\\€\\%\\&\\/\\(\\)\\=\\!]{${minChars},}`, 'g')).test(str)
}
/**
 * Verifica una password che abbia le caratterische richieste
 * @param _password 
 * @param minLength 
 * @param upperCaseMin 
 * @param lowerCase 
 * @param numeric 
 * @param specialChars 
 */
export function checkPasswordPolicy(_password:string, {minLength, upperCaseMin, lowerCase, numeric,  specialChars}: {
    minLength: number, upperCaseMin: number, lowerCase: number , numeric: number ,  specialChars: number
} = {
    lowerCase: 1,
    minLength: 6,
    numeric: 1,
    specialChars: 1,
    upperCaseMin: 1
}): boolean {

    try {
        
        if(!_password || _password.length < minLength){
            return false;
        }

        if(!hasUpperCase(_password, upperCaseMin) || 
            !hasLowerCase(_password, lowerCase) || 
            !hasNumeric(_password,numeric) || 
            !hasSpecialChars(_password,specialChars)){
            return false;
        }

        return true;

    } catch (error) {
        console.log(error);
    }
    return false
}