package lite.util;

class Util {
	public static function resolveEnum<T:Enum<T>>(myEnumInstance:T):T {
		return myEnumInstance;
	}
}
