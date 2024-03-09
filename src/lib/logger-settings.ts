const logger = console;

logger.debug = (message?: any, ...optionalParams: any[]): void =>{
    if(process.env.NODE_ENV === "development"){
        console.log(message,...optionalParams);
    }
}

export default logger;