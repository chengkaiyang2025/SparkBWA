/**
 * Copyright 2016 José Manuel Abuín Mosquera <josemanuel.abuin@usc.es>
 *
 * <p>This file is part of SparkBWA.
 *
 * <p>SparkBWA is free software: you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * <p>SparkBWA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * <p>You should have received a copy of the GNU General Public License along with SparkBWA. If not,
 * see <http://www.gnu.org/licenses/>.
 */
package com.github.sparkbwa;

import cz.adamh.utils.NativeUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.io.IOException;
import java.util.Arrays;

/**
 * Class that calls BWA functions by means of JNI
 *
 * @author José M. Abuín
 */

public class BwaJni {
    private static final Log LOG 				= LogFactory.getLog(BwaJni.class);

	static {
		try {
			NativeUtils.loadLibraryFromJar("/libbwa.so");
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Function to call BWA native main method from Java
	 * @param args A String array with the arguments to call BWA
	 * @return The BWA integer result value
	 */
	public static int Bwa_Jni(String[] args) {

		int[] lenStrings = new int[args.length];

		int i = 0;

		for (String argumento : args) {
			lenStrings[i] = argumento.length();
		}

        LOG.info("Start to call native BwaJni with parameters: " + args);
		int returnCode = new BwaJni().bwa_jni(args.length, args, lenStrings);
        LOG.info("End to call native BwaJni with parameters: " + args + ", returnCode: " + returnCode);

		return returnCode;
	}

	//Declaration of native method
	private native int bwa_jni(int argc, String[] argv, int[] lenStrings);
}
