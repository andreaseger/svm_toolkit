//
// Model
//
package libsvm;
public class Model implements java.io.Serializable
{
	public Parameter param;	// parameter
	public int nr_class;		// number of classes, = 2 in regression/one class svm
	public int l;			// total #SV
	public Node[][] SV;	// SVs (SV[l])
  public int[] sv_indices; // indices of support vectors from training set - PCL
	public double[][] sv_coef;	// coefficients for SVs in decision functions (sv_coef[k-1][l])
	public double[] rho;		// constants in decision functions (rho[k*(k-1)/2])
  public double[] w_2;   // hyperplane squared norms for each binary SVM (PCL, taken from Gabor Melis)
	public double[] probA;         // pariwise probability information
	public double[] probB;

	// for classification only

	public int[] label;		// label of each class (label[k])
	public int[] nSV;		// number of SVs for each class (nSV[k])
				// nSV[0] + nSV[1] + ... + nSV[k-1] = l
};
